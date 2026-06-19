import { useState } from "react";
import { Plus, Pencil, Trash2, GripVertical, ChevronUp, ChevronDown } from "lucide-react";
import { Modal } from "../components/Modal";
import { Badge } from "../components/Badge";
import { adminChapters } from "../adminData";

interface Chapter {
  id: number;
  title: string;
  order: number;
  lessonsCount: number;
  created: string;
  status: string;
}

export function AdminChapters() {
  const [chapters, setChapters] = useState<Chapter[]>(adminChapters);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Chapter | null>(null);
  const [form, setForm] = useState({ title: "", order: "", status: "published" });
  const [deleteId, setDeleteId] = useState<number | null>(null);

  const openAdd = () => {
    setEditing(null);
    setForm({ title: "", order: String(chapters.length + 1), status: "published" });
    setModalOpen(true);
  };

  const openEdit = (ch: Chapter) => {
    setEditing(ch);
    setForm({ title: ch.title, order: String(ch.order), status: ch.status });
    setModalOpen(true);
  };

  const handleSave = () => {
    if (!form.title.trim()) return;
    if (editing) {
      setChapters((prev) =>
        prev.map((c) => c.id === editing.id ? { ...c, title: form.title, order: Number(form.order), status: form.status } : c)
      );
    } else {
      setChapters((prev) => [
        ...prev,
        { id: Date.now(), title: form.title, order: Number(form.order), lessonsCount: 0, created: "10/06/2026", status: form.status },
      ]);
    }
    setModalOpen(false);
  };

  const handleDelete = (id: number) => {
    setChapters((prev) => prev.filter((c) => c.id !== id));
    setDeleteId(null);
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      {/* Toolbar */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <p className="text-slate-500 text-sm font-medium">{chapters.length} chương · {chapters.filter(c => c.status === "published").length} đã xuất bản</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-primary rounded-xl text-white font-black text-sm hover:bg-primary/90 transition active:scale-95"
        >
          <Plus size={16} /> Thêm chương
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-100">
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide w-10"></th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">
                <span className="flex items-center gap-1">Tên chương <ChevronUp size={12} /></span>
              </th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Thứ tự</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Số bài học</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Trạng thái</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Ngày tạo</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {chapters.map((ch) => (
              <tr key={ch.id} className="hover:bg-slate-50/50 transition-colors group">
                <td className="px-5 py-4 text-slate-300 group-hover:text-slate-400">
                  <GripVertical size={16} />
                </td>
                <td className="px-5 py-4">
                  <p className="text-[#0F172A] font-black text-sm">{ch.title}</p>
                </td>
                <td className="px-5 py-4 text-center">
                  <div className="flex items-center justify-center gap-1">
                    <button className="text-slate-300 hover:text-slate-600 transition"><ChevronUp size={14} /></button>
                    <span className="w-6 text-center text-slate-700 font-black text-sm">{ch.order}</span>
                    <button className="text-slate-300 hover:text-slate-600 transition"><ChevronDown size={14} /></button>
                  </div>
                </td>
                <td className="px-5 py-4 text-center">
                  <span className="font-black text-slate-700 text-sm">{ch.lessonsCount}</span>
                </td>
                <td className="px-5 py-4">
                  <Badge
                    label={ch.status === "published" ? "Đã xuất bản" : "Nháp"}
                    variant={ch.status === "published" ? "success" : "warning"}
                  />
                </td>
                <td className="px-5 py-4 text-slate-500 text-sm font-medium">{ch.created}</td>
                <td className="px-5 py-4">
                  <div className="flex items-center justify-center gap-2">
                    <button
                      onClick={() => openEdit(ch)}
                      className="w-8 h-8 flex items-center justify-center rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition"
                    >
                      <Pencil size={14} />
                    </button>
                    <button
                      onClick={() => setDeleteId(ch.id)}
                      className="w-8 h-8 flex items-center justify-center rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Add/Edit Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? "Chỉnh sửa chương" : "Thêm chương mới"}>
        <div className="flex flex-col gap-4">
          <div>
            <label className="text-sm font-black text-slate-700 block mb-1.5">Tên chương *</label>
            <input
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="VD: Quang học cơ bản"
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
            />
          </div>
          <div>
            <label className="text-sm font-black text-slate-700 block mb-1.5">Thứ tự hiển thị</label>
            <input
              type="number"
              value={form.order}
              onChange={(e) => setForm({ ...form, order: e.target.value })}
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
            />
          </div>
          <div>
            <label className="text-sm font-black text-slate-700 block mb-1.5">Trạng thái</label>
            <select
              value={form.status}
              onChange={(e) => setForm({ ...form, status: e.target.value })}
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
            >
              <option value="published">Đã xuất bản</option>
              <option value="draft">Nháp</option>
            </select>
          </div>
          <div className="flex gap-3 pt-2">
            <button onClick={() => setModalOpen(false)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700 hover:bg-slate-200 transition">
              Hủy
            </button>
            <button onClick={handleSave} className="flex-1 py-3 bg-primary rounded-xl font-black text-white hover:bg-primary/90 transition">
              {editing ? "Lưu thay đổi" : "Thêm chương"}
            </button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirm */}
      <Modal open={deleteId !== null} onClose={() => setDeleteId(null)} title="Xóa chương học" width="max-w-sm">
        <div className="text-center">
          <div className="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">🗑️</div>
          <p className="text-slate-600 text-sm font-medium">Bạn có chắc muốn xóa chương này? Hành động này không thể hoàn tác.</p>
          <div className="flex gap-3 mt-5">
            <button onClick={() => setDeleteId(null)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700">Hủy</button>
            <button onClick={() => deleteId && handleDelete(deleteId)} className="flex-1 py-3 bg-red-500 rounded-xl font-black text-white">Xóa</button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
