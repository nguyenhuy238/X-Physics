import { Search, Flame, Award } from "lucide-react";
import { adminStudents } from "../adminData";
import { Badge } from "../components/Badge";
import { useState } from "react";

export function AdminStudents() {
  const [search, setSearch] = useState("");
  const filtered = adminStudents.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-5">
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm kiếm học sinh..."
            className="pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary w-64 transition"
          />
        </div>
        <p className="text-slate-500 text-sm font-medium">{filtered.length} học sinh</p>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-100">
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Học sinh</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Lớp</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Bài học</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Điểm TB</th>
              <th className="text-center px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Streak</th>
              <th className="text-left px-5 py-3.5 text-slate-500 text-xs font-black uppercase tracking-wide">Hoạt động</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {filtered.map((student) => (
              <tr key={student.id} className="hover:bg-slate-50/50 transition-colors">
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 bg-primary/10 rounded-full flex items-center justify-center text-base shrink-0">🧑‍🎓</div>
                    <div>
                      <p className="text-[#0F172A] font-black text-sm">{student.name}</p>
                      <p className="text-slate-400 text-xs font-medium">{student.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-4">
                  <Badge label={student.grade} variant="info" />
                </td>
                <td className="px-5 py-4 text-center">
                  <span className="text-slate-700 font-black text-sm">{student.lessons}</span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span className={`font-black text-sm ${student.avgScore >= 8 ? "text-green-600" : student.avgScore >= 6 ? "text-amber-600" : "text-red-500"}`}>
                    {student.avgScore}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  {student.streak > 0 ? (
                    <div className="flex items-center justify-center gap-1">
                      <Flame size={13} className="text-orange-500" />
                      <span className="font-black text-orange-600 text-sm">{student.streak}</span>
                    </div>
                  ) : (
                    <span className="text-slate-300 text-sm">—</span>
                  )}
                </td>
                <td className="px-5 py-4">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${student.lastActive === "Hôm nay" ? "bg-green-400" : student.lastActive === "Hôm qua" ? "bg-amber-400" : "bg-slate-300"}`} />
                    <span className="text-slate-500 text-sm font-medium">{student.lastActive}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Top performers */}
      <div className="mt-6 grid grid-cols-3 gap-4">
        {adminStudents.sort((a, b) => b.avgScore - a.avgScore).slice(0, 3).map((student, i) => (
          <div key={student.id} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm flex items-center gap-4">
            <div className="relative">
              <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-xl">🧑‍🎓</div>
              <div className={`absolute -top-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-black border-2 border-white ${i === 0 ? "bg-secondary text-slate-900" : i === 1 ? "bg-slate-400 text-white" : "bg-amber-600 text-white"}`}>
                {i + 1}
              </div>
            </div>
            <div className="min-w-0">
              <p className="text-[#0F172A] font-black text-sm truncate">{student.name}</p>
              <div className="flex items-center gap-1 mt-0.5">
                <Award size={12} className="text-amber-500" />
                <span className="text-amber-600 font-black text-xs">{student.avgScore} điểm</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
