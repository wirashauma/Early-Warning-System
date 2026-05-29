import { Injectable, MessageEvent } from '@nestjs/common';
import { Subject, Observable } from 'rxjs';
import { EventEmitter } from 'events';

@Injectable()
export class RealtimeService {
  private static readonly emitter = new EventEmitter();
  private readonly sensorSubject = new Subject<MessageEvent>();

  emitSensorUpdate(data: any): void {
    // 1. Push to local subject for local callers
    this.sensorSubject.next({ data } as MessageEvent);

    // 2. Broadcast globally across service instances via static EventEmitter
    RealtimeService.emitter.emit('sensor.telemetry.new', data);
  }

  getSensorStream(): Observable<MessageEvent> {
    return new Observable<MessageEvent>((subscriber) => {
      // Direct subscriber to static EventEmitter delivers cross-instance updates safely
      const handler = (data: any) => {
        subscriber.next({ data } as MessageEvent);
      };

      RealtimeService.emitter.on('sensor.telemetry.new', handler);

      // Also pipe local subject events
      const sub = this.sensorSubject.subscribe({
        next: (val) => subscriber.next(val),
        error: (err) => subscriber.error(err),
        complete: () => subscriber.complete(),
      });

      return () => {
        RealtimeService.emitter.off('sensor.telemetry.new', handler);
        sub.unsubscribe();
      };
    });
  }
}
