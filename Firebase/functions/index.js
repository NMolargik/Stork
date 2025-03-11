const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Load Gmail credentials from Firebase Config
const gmailEmail = process.env.GMAIL_EMAIL || null;
const gmailPassword = process.env.GMAIL_PASSWORD || null;

if (!gmailEmail || !gmailPassword) {
    console.error("❌ Missing Gmail credentials. Make sure they are set in Firebase config.");
}

// Configure Nodemailer transporter
const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: gmailEmail,
        pass: gmailPassword,
    },
});

// ✅ Firestore Trigger: Runs when a new Hospital document is created
exports.sendNewHospitalEmail = onDocumentCreated("Hospital/{hospitalId}", async (event) => {
    try {
        if (!event.data) {
            console.warn("⚠️ No event data received. Skipping email send.");
            return;
        }

        const newHospital = event.data.data();
        console.log("🏥 New hospital added:", newHospital);

        if (!newHospital || !newHospital.name) {
            console.warn("⚠️ Missing hospital name. Email not sent.");
            return;
        }

        const mailOptions = {
            from: gmailEmail,
            to: "nmolargik@gmail.com",
            subject: "New Hospital Added",
            text: `A new hospital has been added: ${newHospital.name}`,
            html: `<p>A new hospital has been added: <strong>${newHospital.name}</strong></p>`,
        };

        await transporter.sendMail(mailOptions);
        console.log("✅ Email sent successfully for hospital:", newHospital.name);

    } catch (error) {
        console.error("❌ Error sending email:", error);
    }
});