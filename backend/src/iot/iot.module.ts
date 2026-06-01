import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { IotController } from './iot.controller';
import { IotService } from './iot.service';
import { EmailModule } from '../common/email/email.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { AlertsModule } from '../alerts/alerts.module';

@Module({
  imports: [PrismaModule, EmailModule, RealtimeModule, AlertsModule],
  controllers: [IotController],
  providers: [IotService],
})
export class IotModule {}
