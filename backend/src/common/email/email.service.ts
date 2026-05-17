import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import nodemailer, { type Transporter } from 'nodemailer';
import { PrismaService } from '../../prisma/prisma.service';

interface BroadcastEmailPayload {
  title: string;
  message: string;
  severity: string;
  targetArea?: string | null;
  alertId?: string;
}

export interface BroadcastEmailResult {
  attempted: boolean;
  skippedReason?: string;
  recipientCount?: number;
  messageId?: string;
  response?: string;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: Transporter | null = null;
  private cachedTransportKey: string | null = null;

  constructor(private readonly prisma: PrismaService) {}

  isEnabled(): boolean {
    return Boolean(
      process.env.SMTP_HOST?.trim() &&
        process.env.SMTP_PORT?.trim() &&
        process.env.SMTP_USER?.trim() &&
        process.env.SMTP_PASS?.trim() &&
        process.env.SMTP_FROM?.trim(),
    );
  }

  async sendBroadcastEmail(
    payload: BroadcastEmailPayload,
  ): Promise<BroadcastEmailResult> {
    if (!this.isEnabled()) {
      return {
        attempted: false,
        skippedReason: 'Email service belum dikonfigurasi.',
      };
    }

    const recipients = await this.getActiveRecipientEmails();
    if (recipients.length === 0) {
      return {
        attempted: false,
        skippedReason: 'Tidak ada penerima email aktif.',
      };
    }

    const transporter = this.getTransporter();
    if (!transporter) {
      throw new BadRequestException('SMTP transporter gagal dibuat.');
    }

    const from = process.env.SMTP_FROM!.trim();
    const subject = payload.title.trim();
    const textBody = this.buildPlainTextBody(payload);
    const htmlBody = this.buildHtmlBody(payload);

    const info = await transporter.sendMail({
      from,
      to: from,
      bcc: recipients,
      subject,
      text: textBody,
      html: htmlBody,
      headers: payload.alertId ? { 'X-Alert-Id': payload.alertId } : undefined,
    });

    this.logger.log(
      `Email broadcast sent successfully to ${recipients.length} recipient(s). MessageId=${info.messageId}`,
    );

    return {
      attempted: true,
      recipientCount: recipients.length,
      messageId: info.messageId,
      response: typeof info.response === 'string' ? info.response : undefined,
    };
  }

  private getTransporter(): Transporter | null {
    if (!this.isEnabled()) {
      return null;
    }

    const transportKey = [
      process.env.SMTP_HOST?.trim(),
      process.env.SMTP_PORT?.trim(),
      process.env.SMTP_USER?.trim(),
      process.env.SMTP_PASS?.trim(),
      process.env.SMTP_SECURE?.trim() ?? '',
    ].join('|');

    if (this.transporter && this.cachedTransportKey === transportKey) {
      return this.transporter;
    }

    const port = Number(process.env.SMTP_PORT);
    const secure = (process.env.SMTP_SECURE ?? '').toLowerCase() === 'true' || port === 465;

    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST!.trim(),
      port,
      secure,
      auth: {
        user: process.env.SMTP_USER!.trim(),
        pass: process.env.SMTP_PASS!.trim(),
      },
    });
    this.cachedTransportKey = transportKey;

    return this.transporter;
  }

  private async getActiveRecipientEmails(): Promise<string[]> {
    const users = await this.prisma.user.findMany({
      where: {
        isActive: true,
        email: { not: '' },
        role: { in: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.FIELD_OFFICER, UserRole.USER] },
      },
      select: {
        email: true,
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    return [...new Set(users.map((user) => user.email.trim().toLowerCase()).filter(Boolean))];
  }

  private buildPlainTextBody(payload: BroadcastEmailPayload): string {
    const lines = [
      `Judul: ${payload.title}`,
      `Level: ${payload.severity}`,
      payload.targetArea ? `Wilayah: ${payload.targetArea}` : 'Wilayah: Semua Wilayah',
      '',
      payload.message,
      '',
      'Email ini dikirim otomatis dari sistem Early Warning System.',
    ];

    return lines.join('\n');
  }

  private buildHtmlBody(payload: BroadcastEmailPayload): string {
    const safeMessage = payload.message
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean)
      .join('<br />');

    return `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #0f172a;">
        <h2 style="margin: 0 0 12px; color: #b91c1c;">${this.escapeHtml(payload.title)}</h2>
        <p style="margin: 0 0 8px;"><strong>Level:</strong> ${this.escapeHtml(payload.severity)}</p>
        <p style="margin: 0 0 16px;"><strong>Wilayah:</strong> ${this.escapeHtml(payload.targetArea ?? 'Semua Wilayah')}</p>
        <div style="padding: 16px; border-radius: 12px; background: #f8fafc; border: 1px solid #e2e8f0;">
          <p style="margin: 0; white-space: pre-line;">${safeMessage}</p>
        </div>
        <p style="margin-top: 16px; font-size: 12px; color: #64748b;">Email ini dikirim otomatis dari sistem Early Warning System.</p>
      </div>
    `;
  }

  private escapeHtml(value: string): string {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }
}
