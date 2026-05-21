import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { DischargeController } from './discharge.controller';
import { DischargeService } from './discharge.service';

@Module({
  imports: [PrismaModule],
  controllers: [DischargeController],
  providers: [DischargeService],
  exports: [DischargeService],
})
export class DischargeModule {}
