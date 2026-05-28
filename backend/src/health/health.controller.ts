import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ok } from '../common/api-response';
import { PrismaService } from '../prisma/prisma.service';
import { Public } from '../auth/public.decorator';

@Public()
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async check() {
    return ok({ status: 'ok', service: 'EWS Backend' }, 'Service is healthy');
  }

  @Get('db')
  async checkDatabase() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return ok({ database: 'connected' }, 'Database is connected');
    } catch (error) {
      throw new ServiceUnavailableException('Database connection failed');
    }
  }
}
