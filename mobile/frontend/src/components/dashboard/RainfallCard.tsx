import { Card } from "@/components/ui/Card";

interface RainfallCardProps {
  rainfallMm: number;
}

export function RainfallCard({ rainfallMm }: RainfallCardProps) {
  const label = rainfallMm >= 50 ? "Tinggi" : rainfallMm >= 20 ? "Sedang" : "Rendah";

  return (
    <Card>
      <h3 className="text-base font-semibold text-slate-900">Curah Hujan Terkini</h3>
      <p className="mt-3 text-2xl font-bold text-cyan-600">{rainfallMm} mm</p>
      <p className="text-sm text-slate-500">Intensitas: {label}</p>
    </Card>
  );
}
