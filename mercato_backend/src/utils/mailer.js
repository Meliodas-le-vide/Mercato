const nodemailer = require('nodemailer');

/**
 * Envoi d'e-mails via SMTP.
 * Variables .env : SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, MAIL_FROM.
 * Sans SMTP_HOST (développement), l'e-mail n'est pas envoyé : son contenu
 * est affiché dans la console du serveur.
 */
const isConfigured = Boolean(process.env.SMTP_HOST);

const transporter = isConfigured
  ? nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT) || 587,
      secure: Number(process.env.SMTP_PORT) === 465,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD,
      },
    })
  : null;

async function sendMail({ to, subject, text, html }) {
  if (!transporter) {
    console.log(`\n[mailer] SMTP non configuré — e-mail NON envoyé à ${to}`);
    console.log(`[mailer] Sujet : ${subject}\n${text}\n`);
    return;
  }

  await transporter.sendMail({
    from: process.env.MAIL_FROM || process.env.SMTP_USER,
    to,
    subject,
    text,
    html,
  });
}

module.exports = { sendMail };
