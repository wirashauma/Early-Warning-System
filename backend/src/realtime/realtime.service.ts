import { Injectable, MessageEvent } from '@nestjs/common';
import { Subject, Observable } from 'rxjs';

@Injectable()
export class RealtimeService {
  private readonly sensorSubject = new Subject<MessageEvent>();

  emitSensorUpdate(data: any): void {
    this.sensorSubject.next({ data } as MessageEvent);
  }

  getSensorStream(): Observable<MessageEvent> {
    return this.sensorSubject.asObservable();
  }
}
