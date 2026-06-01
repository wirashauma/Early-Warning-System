import { Module } from '@nestjs/common';
import { AlertsController } from './alerts.controller';
import { AlertsService } from './alerts.service';
import { EmailModule } from '../common/email/email.module';
import { FirebaseModule } from '../common/firebase/firebase.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule, FirebaseModule, EmailModule],
  controllers: [AlertsController],
  providers: [AlertsService],
  exports: [AlertsService],
})
export class AlertsModule {}
