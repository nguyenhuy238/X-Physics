import { useState } from "react";
import { Plus, Pencil, Trash2, Eye, Filter } from "lucide-react";
import { Modal } from "../components/Modal";
import { Badge } from "../components/Badge";
import { adminQuestions, adminLessons } from "../adminData";

interface Question {
  id: number;
  lessonId: number;
  lesson: string;
  question: string;
  correct: string;
  difficulty: string;
  created: string;
}

const difficultyConfig: Record<string, { label: string; variant: "success" | "warning" | "error" }> = {
  easy: { label: "Dễ", variant: "success" },
  medium: { label: "Trung bình", variant: "warning" },
  hard: { label: "Khó", variant: "error" },
};

const defaultForm = {
  lessonId: "1",
  question: "",
  optionA: "",
  optionB: "",
  optionC: "",
  optionD: "",
  correct: "A",
  explanation: "",
  difficulty: "medium",
};

export function AdminQuestions() {
  const [questions, setQuestions] = useState<Question[]>(adminQuestions);
  const [filterLesson, setFilterLesson] = useState("all");
  const [modalOpen, setModalOpen] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [previewQuestion, setPreviewQuestion] = useState<Question | null>(null);
  const [editing, setEditing] = useState<Question | null>(null);
  const [form, setForm] = useState(defaultForm);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);

  const filtered = filterLesson === "all" ? questions : questions.filter((q) => q.lessonId === Number(filterLesson));

  const openAdd = () => {
    setEditing(null);
    setForm(defaultForm);
    setModalOpen(true);
  };

  const openEdit = (q: Question) => {
    setEditing(q);
    setForm({ ...defaultForm, lessonId: String(q.lessonId), question: q.question, correct: q.correct.charAt(0), difficulty: q.difficulty });
    setModalOpen(true);
  };

  const handleSave = () => {
    if (!form.question.trim()) return;
    const lessonName = adminLessons.find(l => l.id === Number(form.lessonId))?.title ?? "";
    if (editing) {
      setQuestions(prev => prev.map(q => q.id === editing.id ? {
        ...q, lessonId: Number(form.lessonId), lesson: lessonName,
        question: form.question, correct: `${form.correct}. ${form["option" + form.correct as keyof typeof form] || "..."}`,
        difficulty: form.difficulty
      } : q));
    } else {
      setQuestions(prev => [...prev, {
        id: Date.now(), lessonId: Number(form.lessonId), lesson: lessonName,
        question: form.question,
        correct: `${form.correct}. ${form["option" + form.correct as keyof typeof form] || "..."}`,
        difficulty: form.difficulty, created: "10/06/2026"
      }]);
    }
    setModalOpen(false);
  };

  const optionLetters = ["A", "B", "C", "D"] as const;
  const optionKeys = ["optionA", "optionB", "optionC", "optionD"] as const;

  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-5">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 py-2.5">
            <Filter size={14} className="text-slate-400" />
            <select value={filterLesson} onChange={(e) => setFilterLesson(e.target.value)} className="bg-transparent text-sm font-semibold text-slate-700 focus:outline-none">
              <option value="all">Tất cả bài học</option>
              {adminLessons.map((l) => <option key={l.id} value={l.id}>{l.title}</option>)}
            </select>
          </div>
          <p className="text-slate-500 text-sm font-medium">{filtered.length} câu hỏi</p>
        </div>
        <button onClick={openAdd} className="flex items-center gap-2 px-4 py-2.5 bg-primary rounded-xl text-white font-black text-sm hover:bg-primary/90 transition active:scale-95">
          <Plus size={16} /> Thêm câu hỏi
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-100">
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide w-8">#</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Câu hỏi</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Bài học</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Đáp án đúng</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Độ khó</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Ngày tạo</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Thao tác</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {filtered.map((q, i) => (
              <tr key={q.id} className="hover:bg-slate-50/50 transition-colors">
                <td className="px-5 py-4 text-slate-400 text-sm font-semibold">{i + 1}</td>
                <td className="px-5 py-4 max-w-xs">
                  <p className="text-[#0F172A] font-semibold text-sm truncate">{q.question}</p>
                </td>
                <td className="px-5 py-4">
                  <span className="text-slate-500 text-sm font-medium">{q.lesson}</span>
                </td>
                <td className="px-5 py-4">
                  <span className="text-green-600 font-black text-sm">{q.correct}</span>
                </td>
                <td className="px-5 py-4 text-center">
                  <Badge label={difficultyConfig[q.difficulty].label} variant={difficultyConfig[q.difficulty].variant} />
                </td>
                <td className="px-5 py-4 text-slate-500 text-sm font-medium">{q.created}</td>
                <td className="px-5 py-4">
                  <div className="flex items-center justify-center gap-2">
                    <button onClick={() => { setPreviewQuestion(q); setSelectedOption(null); setPreviewOpen(true); }} className="w-8 h-8 flex items-center justify-center rounded-lg bg-slate-50 text-slate-500 hover:bg-slate-100 transition">
                      <Eye size={14} />
                    </button>
                    <button onClick={() => openEdit(q)} className="w-8 h-8 flex items-center justify-center rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition">
                      <Pencil size={14} />
                    </button>
                    <button onClick={() => setDeleteId(q.id)} className="w-8 h-8 flex items-center justify-center rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition">
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
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? "Chỉnh sửa câu hỏi" : "Thêm câu hỏi mới"} width="max-w-xl">
        <div className="flex flex-col gap-4 max-h-[70vh] overflow-y-auto pr-1">
          <div>
            <label className="text-xs font-black text-slate-700 block mb-1.5">Bài học</label>
            <select value={form.lessonId} onChange={(e) => setForm({ ...form, lessonId: e.target.value })} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition">
              {adminLessons.map((l) => <option key={l.id} value={l.id}>{l.title}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs font-black text-slate-700 block mb-1.5">Nội dung câu hỏi *</label>
            <textarea
              value={form.question}
              onChange={(e) => setForm({ ...form, question: e.target.value })}
              placeholder="Nhập câu hỏi vật lý..."
              rows={2}
              className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition resize-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            {optionLetters.map((letter, idx) => (
              <div key={letter}>
                <label className="text-xs font-black text-slate-700 block mb-1.5">
                  Đáp án {letter} {form.correct === letter && <span className="text-green-600">✓ Đúng</span>}
                </label>
                <input
                  value={form[optionKeys[idx]]}
                  onChange={(e) => setForm({ ...form, [optionKeys[idx]]: e.target.value })}
                  placeholder={`Đáp án ${letter}...`}
                  className={`w-full px-3 py-2.5 bg-slate-50 border rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition ${form.correct === letter ? "border-green-300 bg-green-50/30" : "border-slate-200"}`}
                />
              </div>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-black text-slate-700 block mb-1.5">Đáp án đúng</label>
              <div className="flex gap-2">
                {optionLetters.map((letter) => (
                  <button
                    key={letter}
                    onClick={() => setForm({ ...form, correct: letter })}
                    className={`w-10 h-10 rounded-xl font-black text-sm transition ${form.correct === letter ? "bg-green-500 text-white shadow-sm" : "bg-slate-100 text-slate-500 hover:bg-slate-200"}`}
                  >
                    {letter}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="text-xs font-black text-slate-700 block mb-1.5">Độ khó</label>
              <select value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })} className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition">
                <option value="easy">Dễ</option>
                <option value="medium">Trung bình</option>
                <option value="hard">Khó</option>
              </select>
            </div>
          </div>

          <div>
            <label className="text-xs font-black text-slate-700 block mb-1.5">Giải thích đáp án</label>
            <textarea
              value={form.explanation}
              onChange={(e) => setForm({ ...form, explanation: e.target.value })}
              placeholder="Giải thích tại sao đáp án đúng..."
              rows={2}
              className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition resize-none"
            />
          </div>
        </div>
        <div className="flex gap-3 pt-4">
          <button onClick={() => setModalOpen(false)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700 hover:bg-slate-200 transition">Hủy</button>
          <button onClick={handleSave} className="flex-1 py-3 bg-primary rounded-xl font-black text-white hover:bg-primary/90 transition">{editing ? "Lưu thay đổi" : "Thêm câu hỏi"}</button>
        </div>
      </Modal>

      {/* Preview modal */}
      <Modal open={previewOpen} onClose={() => setPreviewOpen(false)} title="Xem trước câu hỏi" width="max-w-md">
        {previewQuestion && (
          <div>
            <div className="bg-slate-50 rounded-2xl p-4 mb-4">
              <p className="text-[#0F172A] font-black text-sm leading-relaxed">{previewQuestion.question}</p>
            </div>
            <div className="flex flex-col gap-2 mb-4">
              {["A", "B", "C", "D"].map((letter) => {
                const isCorrect = previewQuestion.correct.startsWith(letter);
                const isSelected = selectedOption === letter;
                return (
                  <button
                    key={letter}
                    onClick={() => setSelectedOption(letter)}
                    className={`flex items-center gap-3 p-3 rounded-xl border-2 text-left transition-all ${
                      isSelected && isCorrect ? "border-green-400 bg-green-50" :
                      isSelected && !isCorrect ? "border-red-400 bg-red-50" :
                      isCorrect && selectedOption ? "border-green-300 bg-green-50/50" :
                      "border-slate-200 hover:border-slate-300"
                    }`}
                  >
                    <div className={`w-7 h-7 rounded-lg flex items-center justify-center font-black text-xs shrink-0 ${isSelected ? (isCorrect ? "bg-green-500 text-white" : "bg-red-500 text-white") : "bg-slate-100 text-slate-500"}`}>{letter}</div>
                    <span className="text-sm font-semibold text-slate-700">Đáp án {letter}</span>
                  </button>
                );
              })}
            </div>
            {selectedOption && (
              <div className="bg-blue-50 rounded-xl p-3 text-sm text-blue-700 font-medium">
                💡 Đáp án đúng: <span className="font-black">{previewQuestion.correct}</span>
              </div>
            )}
            <button onClick={() => setPreviewOpen(false)} className="w-full mt-4 py-3 bg-slate-100 rounded-xl font-black text-slate-700">Đóng</button>
          </div>
        )}
      </Modal>

      {/* Delete confirm */}
      <Modal open={deleteId !== null} onClose={() => setDeleteId(null)} title="Xóa câu hỏi" width="max-w-sm">
        <div className="text-center">
          <div className="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">🗑️</div>
          <p className="text-slate-600 text-sm font-medium">Bạn có chắc muốn xóa câu hỏi này không?</p>
          <div className="flex gap-3 mt-5">
            <button onClick={() => setDeleteId(null)} className="flex-1 py-3 bg-slate-100 rounded-xl font-black text-slate-700">Hủy</button>
            <button onClick={() => { setQuestions(p => p.filter(q => q.id !== deleteId)); setDeleteId(null); }} className="flex-1 py-3 bg-red-500 rounded-xl font-black text-white">Xóa</button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
