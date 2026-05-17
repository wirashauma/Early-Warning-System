import { Module } from '@nestjs/common';
import { FlowRateController } from './flow-rate.controller';
import { FlowRateService } from './flow-rate.service';

@Module({
  controllers: [FlowRateController],
  providers: [FlowRateService],
})
export class FlowRateModule {}
