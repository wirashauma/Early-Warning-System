import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { mockUsers } from "@/constants";

export default function AdminUsersPage() {
  return (
    <main className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-900">User Management</h1>
        <Button>Tambah User</Button>
      </div>

      <Card className="overflow-x-auto">
        <table className="w-full min-w-140 text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="py-2">Nama</th>
              <th className="py-2">Email</th>
              <th className="py-2">Role</th>
              <th className="py-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {mockUsers.map((user) => (
              <tr key={user.id} className="border-b border-slate-100">
                <td className="py-3">{user.name}</td>
                <td className="py-3">{user.email}</td>
                <td className="py-3">{user.role}</td>
                <td className="py-3">
                  <div className="flex gap-2">
                    <Button variant="secondary">Edit</Button>
                    <Button variant="danger">Hapus</Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </main>
  );
}
