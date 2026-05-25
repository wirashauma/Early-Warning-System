import { Controller, HttpCode, Put, Request, UseGuards } from '@nestjs/common';
import { ok } from '../common/api-response';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

interface AuthenticatedRequest {
  user: {
    id: string;
    email: string;
    role: string;
  };
}

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @UseGuards(JwtAuthGuard)
  @Put('read-all')
  @HttpCode(200)
  async markAllRead(@Request() req: AuthenticatedRequest) {
    const data = await this.notificationsService.markAllRead(req.user.id);
    return ok(data);
  }
}