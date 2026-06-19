import { useState } from "react";
import { Plus, Pencil, Trash2, Eye, Filter } from "lucide-react";
import { Modal } from "../components/Modal";
import { Badge } from "../components/Badge";
import { adminLessons, adminChapters } from "../adminData";

interface Lesson {
  id: number;
  title: string;
  chapterId: number;
  chapter: string;
  summary: string;
  minutes: number;
  status: string;
  created: string;
}

const defaultForm = {
  title: "",
  chapterId: "1",
  summary: "",
  content: "## Giới thiệu\n\nNội dung bài học...\n\n## Công thức\n\n$$s = v \\times t$$\n\n## Ví dụ\n\n...",
  formulaJson: '{"name":"s = v × t","variables":[{"id":"v","label":"Vận tốc","unit":"m/s","min":1,"max":20},{"id":"t","label":"Thời gian","unit":"s","min":1,"max":60}]}',
  minutes: "10",
  status: "published",
};

export function AdminLessons() {
  const [lessons, setLessons] = useState<Lesson[]>(adminLessons);
  const [filterChapter, setFilterChapter] = useState("all");
  const [modalOpen, setModalOpen] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [editing, setEditing] = useState<Lesson | null>(null);
  const [form, setForm] = useState(defaultForm);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<"form" | "preview">("form");

  const filtered = filterChapter === "all" ? lessons : lessons.filter((l) => l.chapterId === Number(filterChapter));

  const openAdd = () => {
    setEditing(null);
    setForm(defaultForm);
    setActiveTab("form");
    setModalOpen(true);
  };

  const openEdit = (l: Lesson) => {
    setEditing(l);
    setForm({ ...defaultForm, title: l.title, chapterId: String(l.chapterId), summary: l.summary, minutes: String(l.minutes), status: l.status });
    setActiveTab("form");
    setModalOpen(true);
  };

  const handleSave = () => {
    if (!form.title.trim()) return;
    const chName = adminChapters.find(c => c.id === Number(form.chapterId))?.title ?? "";
    if (editing) {
      setLessons(prev => prev.map(l => l.id === editing.id ? { ...l, ...form, chapterId: Number(form.chapterId), chapter: chName, minutes: Number(form.minutes) } : l));
    } else {
      setLessons(prev => [...prev, { id: Date.now(), title: form.title, chapterId: Number(form.chapterId), chapter: chName, summary: form.summary, minutes: Number(form.minutes), status: form.status, created: "10/06/2026" }]);
    }
    setModalOpen(false);
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-5">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 py-2.5">
            <Filter size={14} className="text-slate-400" />
            <select
              value={filterChapter}
              onChange={(e) => setFilterChapter(e.target.value)}
              className="bg-transparent text-sm font-semibold text-slate-700 focus:outline-none"
            >
              <option value="all">Tất cả chương</option>
              {adminChapters.map((c) => (
                <option key={c.id} value={c.id}>{c.title}</option>
              ))}
            </select>
          </div>
          <p className="text-slate-500 text-sm font-medium">{filtered.length} bài học</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-primary rounded-xl text-white font-black text-sm hover:bg-primary/90 transition active:scale-95"
        >
          <Plus size={16} /> Thêm bài học
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-100">
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Tên bài học</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Chương</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Tóm tắt</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Thời gian</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Trạng thái</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Ngày tạo</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {filtered.map((lesson) => (
              <tr key={lesson.id} className="hover:bg-slate-50/50 transition-colors">
                <td className="px-5 py-4">
                  <p className="text-[#0F172A] font-black text-sm">{lesson.title}</p>
                </td>
                <td className="px-5 py-4">
                  <span className="text-slate-500 text-sm font-medium">{lesson.chapter}</span>
                </td>
                <td className="px-5 py-4 max-w-xs">
                  <p className="text-slate-400 text-xs font-medium truncate">{lesson.summary}</p>
                </td>
                <td className="px-5 py-4 text-center">
                  <span className="text-slate-700 font-black text-sm">{lesson.minutes}m</span>
                </td>
                <td className="px-5 py-4">
                  <Badge label={lesson.status === "published" ? "Đã xuất bản" : "Nháp"} variant={lesson.status === "published" ? "success" : "warning"} />
                </td>
                <td className="px-5 py-4 text-slate-500 text-sm font-medium">{lesson.created}</td>
                <td className="px-5 py-4">
                  <div className="flex items-center justify-center gap-2">
                    <button onClick={() => setPreviewOpen(true)} className="w-8 h-8 flex items-center justify-center rounded-lg bg-slate-50 text-slate-500 hover:bg-slate-100 transition">
                      <Eye size={14} />
                    </button>
                    <button onClick={() => openEdit(lesson)} className="w-8 h-8 flex items-center justify-center rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition">
                      <Pencil size={14} />
                    </button>
                    <button onClick={() => setDeleteId(lesson.id)} className="w-8 h-8 flex items-center justify-center rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition">
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
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? "Chỉnh sửa bài học" : "Thêm bài học mới"} width="max-w-2xl">
        {/* Tabs */}
        <div className="flex gap-1 bg-slate-100 rounded-xl p-1 mb-5">
          {(["form", "preview"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-lg text-sm font-black transition ${activeTab === tab ? "bg-white text-[#0F172A] shadow-sm" : "text-slate-500 hover:text-slate-700"}`}
            >
              {tab === "form" ? "✏️ Chỉnh sửa" : "👁️ Xem trước"}
            </button>
          ))}
        </div>

        {activeTab === "form" ? (
          <div className="flex flex-col gap-4 max-h-[60vh] overflow-y-auto pr-1">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-black text-slate-700 block mb-1.5">Tên bài học *</label>
                <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="VD: Định luật Newton" className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition" />
              </div>
              <div>
                <label className="text-xs font-black text-slate-700 block mb-1.5">Chương</label>
                <select value={form.chapterId} onChange={(e) => setForm({ ...form, chapterId: e.target.value })} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition">
                  {adminChapters.map((c) => <option key={c.id} value={c.id}>{c.title}</option>)}
                </select>
              </div>
            </div>
            <div>
              <label className="text-xs font-black text-slate-700 block mb-1.5">Tóm tắt</label>
              <input value={form.summary} onChange={(e) => setForm({ ...form, summary: e.target.value })} placeholder="Mô tả ngắn về bài học" className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition" />
            </div>
            <div>
              <label className="text-xs font-black text-slate-700 block mb-1.5">Nội dung (Markdown)</label>
              <textarea value={form.content} onChange={(e) => setForm({ ...form, content: e.target.value })} rows={5} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 font-mono focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition resize-none" />
            </div>
            <div>
              <label className="text-xs font-black text-slate-700 block mb-1.5">Formula JSON</label>
              <textarea value={form.formulaJson} onChange={(e) => setForm({ ...form, formulaJson: e.target.value })} rows={3} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-600 font-mono focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition resize-none" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-black text-slate-700 block mb-1.5">Thời gian (phút)</label>
                <input type="number" value={form.minutes} onChange={(e) => setForm({ ...form, minutes: e.target.value })} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition" />
              </div>
              <div>
                <label className="text-xs font-black text-slate-700 block mb-1.5">Trạng thái</label>
                <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition">
                  <option value="published">Đã xuất bản</option>
                  <option value="draft">Nháp</option>
                </select>
              </div>
            </div>
          </div>
        ) : (
          <div className="bg-slate-50 rounded-xl p-5 max-h-[60vh] overflow-y-auto">
            <div className="bg-primary rounded-xl p-4 mb-4">
              <h2 className="text-white font-black text-lg">{form.title || "Tên bài học"}</h2>
              <p className="text-blue-200 text-sm mt-1">{form.summary || "Tóm tắt..."}</p>
              <div className="flex gap-3 mt-2">
                <span className="text-blue-200 text-xs">⏱ {form.minutes} phút</span>
                <span className="text-blue-200 text-xs">📚 {adminChapters.find(c => c.id === Number(form.chapterId))?.title}</span>
              </div>
            </div>
            <div className="bg-white rounded-xl p-4 font-mono text-xs text-slate-600 whitespace-pre-wrap">
              {form.content}
            </div>
          </div>
        )}

        <div className="flex gap-3 pt-4">
          <button onClick={() => setModalOpen(false)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700 hover:bg-slate-200 transition">Hủy</button>
          <button onClick={handleSave} className="flex-1 py-3 bg-primary rounded-xl font-black text-white hover:bg-primary/90 transition">{editing ? "Lưu thay đổi" : "Thêm bài học"}</button>
        </div>
      </Modal>

      {/* Preview only modal */}
      <Modal open={previewOpen} onClose={() => setPreviewOpen(false)} title="Xem trước bài học" width="max-w-lg">
        <div className="bg-primary rounded-xl p-4 mb-3">
          <h2 className="text-white font-black text-base">Chuyển động đều</h2>
          <p className="text-blue-200 text-sm mt-1">Khái niệm cơ bản về chuyển động đều</p>
        </div>
        <div className="bg-slate-50 rounded-xl p-4 text-sm text-slate-600">
          <p className="font-black text-slate-700 mb-2">Công thức:</p>
          <div className="bg-white rounded-lg p-3 text-center font-black text-primary text-xl">s = v × t</div>
        </div>
        <button onClick={() => setPreviewOpen(false)} className="w-full mt-4 py-3 bg-slate-100 rounded-xl font-black text-slate-700">Đóng</button>
      </Modal>

      <Modal open={deleteId !== null} onClose={() => setDeleteId(null)} title="Xóa bài học" width="max-w-sm">
        <div className="text-center">
          <div className="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">🗑️</div>
          <p className="text-slate-600 text-sm font-medium">Bạn có chắc muốn xóa bài học này? Câu hỏi liên quan cũng sẽ bị xóa.</p>
          <div className="flex gap-3 mt-5">
            <button onClick={() => setDeleteId(null)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700">Hủy</button>
            <button onClick={() => { setLessons(p => p.filter(l => l.id !== deleteId)); setDeleteId(null); }} className="flex-1 py-3 bg-red-500 rounded-xl font-black text-white">Xóa</button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
