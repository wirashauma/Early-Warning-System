import { SensorMap } from "@/components/maps/SensorMap";
import { mockSensors } from "@/constants";

export default function MapPage() {
  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-8">
      <h1 className="mb-2 text-2xl font-bold text-slate-900">Peta Lokasi Sensor</h1>
      <p className="mb-6 text-sm text-slate-600">
        Integrasi awal peta sensor. Marker detail ditampilkan sebagai daftar lokasi dan tautan Google Maps.
      </p>
      <SensorMap sensors={mockSensors} />
    </main>
  );
}
