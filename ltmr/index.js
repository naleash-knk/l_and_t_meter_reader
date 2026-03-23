const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");
const os = require("os");
const path = require("path");
const fs = require("fs");
const ExcelJS = require("exceljs");

admin.initializeApp();

const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");
const SMTP_FROM = defineSecret("SMTP_FROM");
const DEFAULT_FROM = "sharpfwmsmetalshop@gmail.com";

exports.sendReportEmail = onDocumentCreated(
  {
    document: "mail_requests/{docId}",
    secrets: [SMTP_USER, SMTP_PASS, SMTP_FROM],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};

    try {
      await snap.ref.update({
        status: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore status update failures (permissions/connection) and proceed.
    }

    const smtpUser = SMTP_USER.value();
    const smtpPass = SMTP_PASS.value();
    const from = SMTP_FROM.value() || DEFAULT_FROM;
    if (!smtpUser || !smtpPass) {
      throw new Error("Missing SMTP secrets (SMTP_USER/SMTP_PASS)");
    }

    // Optional SMTP overrides from env vars (no secret prompts during deploy).
    const smtpHost = process.env.SMTP_HOST;
    const smtpPortRaw = process.env.SMTP_PORT;
    const smtpSecureRaw = process.env.SMTP_SECURE;

    const smtpPort = smtpPortRaw ? Number(smtpPortRaw) : undefined;
    if (smtpPortRaw && Number.isNaN(smtpPort)) {
      throw new Error("Invalid SMTP_PORT secret; must be a number");
    }

    const smtpSecure =
      smtpSecureRaw == null
        ? undefined
        : String(smtpSecureRaw).toLowerCase() === "true";

    const transportConfig = smtpHost
      ? {
          host: smtpHost,
          port: smtpPort ?? 587,
          secure: smtpSecure ?? false,
          auth: { user: smtpUser, pass: smtpPass },
        }
      : {
          // Gmail default: requires an App Password (NOT your normal Gmail password)
          // unless you implement OAuth2.
          service: "gmail",
          auth: { user: smtpUser, pass: smtpPass },
        };

    const transporter = nodemailer.createTransport(transportConfig);

    const bucket = admin.storage().bucket();
    const attachments = Array.isArray(data.attachments) && data.attachments.length
      ? data.attachments
      : data.storagePath
      ? [
          {
            storagePath: data.storagePath,
            filename: data.filename || "report.xlsx",
          },
        ]
      : [];

    if (!attachments.length) {
      throw new Error("No attachments provided for email.");
    }

    const tempFiles = attachments.map((att, index) => ({
      storagePath: att.storagePath,
      filename: att.filename || `report_${index + 1}.xlsx`,
      tempFile: path.join(
        os.tmpdir(),
        `${Date.now()}_${att.filename || `report_${index + 1}.xlsx`}`,
      ),
    }));

    try {
      // Download attachments from Firebase Storage
      await Promise.all(
        tempFiles.map((att) =>
          bucket.file(att.storagePath).download({
            destination: att.tempFile,
          }),
        ),
      );

      // Send email with attachment
      await transporter.sendMail({
        from,
        to: data.to,
        subject: data.subject,
        text: data.body,
        attachments: tempFiles.map((att) => ({
          filename: att.filename,
          path: att.tempFile,
        })),
      });

      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (data.cleanup === true) {
        await Promise.all(
          tempFiles.map((att) =>
            bucket.file(att.storagePath).delete().catch(() => {}),
          ),
        );
      }
    } catch (err) {
      const message = err?.message ? String(err.message) : String(err);
      const code = err?.code ? String(err.code) : "";
      const response = err?.response ? String(err.response) : "";

      let actionable = message;
      if (
        code === "EAUTH" ||
        /535\s*-?5\.7\.8/i.test(message) ||
        /BadCredentials/i.test(message) ||
        /Username and password not accepted/i.test(message) ||
        /535\s*-?5\.7\.8/i.test(response) ||
        /BadCredentials/i.test(response)
      ) {
        actionable =
          "SMTP auth failed (Gmail blocks normal passwords). " +
          "Use a Google Account App Password for SMTP_PASS (recommended), " +
          "or switch to a different SMTP provider via SMTP_HOST/SMTP_PORT/SMTP_SECURE.";
      }
      await snap.ref.update({
        status: "error",
        error: actionable,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } finally {
      for (const att of tempFiles) {
        try {
          fs.unlinkSync(att.tempFile);
        } catch (_) {
          // ignore cleanup failures
        }
      }
    }
  },
);

function _getZonedDateParts(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const lookup = Object.fromEntries(
    parts.filter((p) => p.type !== "literal").map((p) => [p.type, p.value]),
  );

  return {
    year: Number(lookup.year),
    month: Number(lookup.month),
    day: Number(lookup.day),
  };
}

async function _buildWorkbookBuffer(collectionName, columns) {
  const snap = await admin.firestore().collection(collectionName).get();
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Sheet1");

  sheet.addRow(columns.map((col) => col.header));

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const row = columns.map((col) => {
      const value = data[col.key];
      if (value == null) return "";
      if (value.toDate) {
        return value.toDate().toISOString();
      }
      if (typeof value === "object") {
        return JSON.stringify(value);
      }
      return String(value);
    });
    sheet.addRow(row);
  }

  return workbook.xlsx.writeBuffer();
}

async function _uploadBuffer(buffer, storagePath) {
  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);
  await file.save(Buffer.from(buffer), {
    contentType:
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
  return storagePath;
}

async function _clearCollection(collectionName) {
  const snap = await admin.firestore().collection(collectionName).get();
  const docs = snap.docs;
  for (let i = 0; i < docs.length; i += 500) {
    const batch = admin.firestore().batch();
    const chunk = docs.slice(i, i + 500);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
  return docs.length;
}

async function _listAllAuthUsers() {
  const users = [];
  let nextPageToken;
  do {
    const page = await admin.auth().listUsers(1000, nextPageToken);
    page.users.forEach((user) => {
      if (user.email) {
        users.push({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName || "",
        });
      }
    });
    nextPageToken = page.pageToken;
  } while (nextPageToken);
  return users;
}

exports.monthEndReports = onSchedule(
  { schedule: "0 23 * * *", timeZone: "Asia/Kolkata" },
  async () => {
    const now = new Date();
    const { year, month, day } = _getZonedDateParts(now, "Asia/Kolkata");
    const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
    if (day !== lastDay) return;

    const monthLabel = `${year}-${String(month).padStart(2, "0")}`;

    const reportDefs = [
      {
        name: "compressor_readings",
        collection: "compressor_readings",
        columns: [
          { key: "Date", header: "Date" },
          { key: "Time", header: "Time" },
          { key: "User Entry", header: "User Entry" },
          { key: "COMP-1 Running HRS", header: "COMP-1 Running HRS" },
          { key: "COMP-1 KWH", header: "COMP-1 KWH" },
          { key: "COMP-2 Running HRS", header: "COMP-2 Running HRS" },
          { key: "COMP-2 KWH", header: "COMP-2 KWH" },
        ],
      },
      {
        name: "solar_panel_readings",
        collection: "solar_panel_readings",
        columns: [
          { key: "Date", header: "Date" },
          { key: "Time", header: "Time" },
          { key: "User Entry", header: "User Entry" },
          { key: "SOLAR-1 KWH", header: "SOLAR-1 KWH" },
        ],
      },
      {
        name: "water_meter_readings",
        collection: "water_meter_readings",
        columns: [
          { key: "Date", header: "Date" },
          { key: "Time", header: "Time" },
          { key: "User Entry", header: "User Entry" },
          { key: "BOREWELL", header: "BOREWELL" },
          { key: "OUTLET", header: "OUTLET" },
          { key: "STPINLET", header: "STPINLET" },
          { key: "STPOUTLET", header: "STPOUTLET" },
          { key: "ETPINLET", header: "ETPINLET" },
          { key: "ETPOUTLET", header: "ETPOUTLET" },
        ],
      },
      {
        name: "activity_logs",
        collection: "activity_logs",
        columns: [
          { key: "createdAt", header: "Created At" },
          { key: "actorName", header: "Actor Name" },
          { key: "actorEmail", header: "Actor Email" },
          { key: "title", header: "Title" },
          { key: "message", header: "Message" },
          { key: "type", header: "Type" },
        ],
      },
    ];

    const attachments = [];
    for (const report of reportDefs) {
      const buffer = await _buildWorkbookBuffer(
        report.collection,
        report.columns,
      );
      const filename = `${report.name}_${monthLabel}.xlsx`;
      const storagePath = `monthly_reports/${monthLabel}/${filename}`;
      await _uploadBuffer(buffer, storagePath);
      attachments.push({ storagePath, filename });
    }

    const clearedMailRequests = await _clearCollection("mail_requests");

    const users = await _listAllAuthUsers();

    for (const user of users) {
      await admin.firestore().collection("mail_requests").add({
        to: String(user.email).trim(),
        subject: `FORMWORK UNIT-METALSHOP Monthly Reports (${monthLabel})`,
        body:
          "Please find the monthly activity and report Excel files attached.",
        attachments,
        status: "queued",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        uid: user.uid || "",
      });
    }

    const cleared = await Promise.all([
      _clearCollection("compressor_readings"),
      _clearCollection("solar_panel_readings"),
      _clearCollection("water_meter_readings"),
      _clearCollection("activity_logs"),
    ]);

    await admin.firestore().collection("activity_logs").add({
      type: "monthly_reset",
      title: "Monthly reset completed",
      message:
        `Monthly reset completed for ${monthLabel}. ` +
        `Excel exports for activities, compressors, solar, and water readings ` +
        `queued to ${users.length} users. ` +
        `Cleared activity logs, mail requests, and all monthly readings.`,
      actorUid: "system",
      actorName: "System",
      actorEmail: "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      clientCreatedAt: new Date().toISOString(),
      metadata: {
        month: monthLabel,
        cleared: {
          compressor: cleared[0],
          solar: cleared[1],
          water: cleared[2],
          activity: cleared[3],
          mailRequests: clearedMailRequests,
        },
        queuedEmails: users.length,
      },
    });
  },
);
