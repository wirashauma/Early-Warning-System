import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async markAllRead(userId: string) {
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { notificationReadAt: new Date() },
      select: { id: true, notificationReadAt: true },
    });

    return {
      userId: updated.id,
      notificationReadAt: updated.notificationReadAt?.toISOString() ?? null,
    };
  }
}