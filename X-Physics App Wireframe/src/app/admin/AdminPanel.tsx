import { useState } from "react";
import { AdminSidebar, AdminPage } from "./AdminSidebar";
import { AdminHeader } from "./AdminHeader";
import { AdminDashboard } from "./pages/AdminDashboard";
import { AdminChapters } from "./pages/AdminChapters";
import { AdminLessons } from "./pages/AdminLessons";
import { AdminQuestions } from "./pages/AdminQuestions";
import { AdminStudents } from "./pages/AdminStudents";
import { AdminStatistics } from "./pages/AdminStatistics";

const pageMeta: Record<AdminPage, { title: string; subtitle: string }> = {
  dashboard: { title: "Dashboard", subtitle: "Tổng quan hệ thống X-Physics" },
  chapters: { title: "Quản lý Chương học", subtitle: "Thêm, sửa, xóa và sắp xếp chương" },
  lessons: { title: "Quản lý Bài học", subtitle: "Soạn nội dung, công thức và bài tập" },
  questions: { title: "Quản lý Câu hỏi", subtitle: "Ngân hàng câu hỏi trắc nghiệm" },
  students: { title: "Quản lý Học sinh", subtitle: "Theo dõi tiến độ và thành tích" },
  statistics: { title: "Thống kê", subtitle: "Phân tích dữ liệu học tập chi tiết" },
};

interface AdminPanelProps {
  onExit: () => void;
}

export function AdminPanel({ onExit }: AdminPanelProps) {
  const [page, setPage] = useState<AdminPage>("dashboard");
  const meta = pageMeta[page];

  return (
    <div className="flex h-screen bg-[#F8FAFC] overflow-hidden" style={{ fontFamily: "'Nunito', 'Inter', sans-serif" }}>
      <AdminSidebar active={page} onNavigate={setPage} onExit={onExit} />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <AdminHeader title={meta.title} subtitle={meta.subtitle} />
        {page === "dashboard" && <AdminDashboard />}
        {page === "chapters" && <AdminChapters />}
        {page === "lessons" && <AdminLessons />}
        {page === "questions" && <AdminQuestions />}
        {page === "students" && <AdminStudents />}
        {page === "statistics" && <AdminStatistics />}
      </div>
    </div>
  );
}
