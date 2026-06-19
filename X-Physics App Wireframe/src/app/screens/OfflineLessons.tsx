import { ArrowLeft, Trash2, Download, CheckCircle } from "lucide-react";
import { motion } from "motion/react";

interface OfflineLessonsProps {
  onBack: () => void;
}

const downloaded = [
  { id: 1, title: "Chuyển động đều", chapter: "Chương 1", size: "2.3 MB", date: "10/06/2026", status: "ready" },
  { id: 2, title: "Vận tốc trung bình", chapter: "Chương 1", size: "1.8 MB", date: "09/06/2026", status: "ready" },
  { id: 3, title: "Lực là gì?", chapter: "Chương 2", size: "3.1 MB", date: "08/06/2026", status: "downloading" },
];

export function OfflineLessons({ onBack }: OfflineLessonsProps) {
  const totalSize = "7.2 MB";

  return (
    <div className="h-full flex flex-col bg-background">
      <div className="bg-card border-b border-border pt-12 pb-3 px-5">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-muted active:scale-90 transition">
            <ArrowLeft size={18} className="text-foreground" />
          </button>
          <div>
            <h1 className="text-foreground font-black text-base">Bài học offline</h1>
            <p className="text-muted-foreground text-xs">Đã tải: {totalSize}</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-6 scrollbar-hide flex flex-col gap-3">
        {downloaded.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-4 mt-20">
            <span className="text-6xl">📱</span>
            <div className="text-center">
              <p className="text-foreground font-black text-base">Bạn chưa tải bài học nào</p>
              <p className="text-muted-foreground text-sm mt-1">Tải bài học để học ngay cả khi không có internet</p>
            </div>
            <button onClick={onBack} className="py-3 px-6 bg-primary rounded-2xl text-white font-black text-sm">
              Khám phá bài học
            </button>
          </div>
        ) : (
          <>
            <div className="bg-primary/5 rounded-2xl p-3 border border-primary/10 flex items-center gap-2">
              <Download size={14} className="text-primary" />
              <p className="text-primary font-semibold text-xs">Học offline khi không có mạng</p>
            </div>

            {downloaded.map((lesson, i) => (
              <motion.div
                key={lesson.id}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.08 }}
                className="bg-card rounded-2xl p-4 border border-border shadow-sm flex items-center gap-3"
              >
                <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center shrink-0">
                  {lesson.status === "ready" ? (
                    <CheckCircle size={18} className="text-green-500" />
                  ) : (
                    <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-foreground font-black text-sm truncate">{lesson.title}</p>
                  <p className="text-muted-foreground text-xs">{lesson.chapter} · {lesson.size} · {lesson.date}</p>
                </div>
                <button className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-destructive/10 active:scale-90 transition">
                  <Trash2 size={15} className="text-destructive/60" />
                </button>
              </motion.div>
            ))}
          </>
        )}
      </div>
    </div>
  );
}
