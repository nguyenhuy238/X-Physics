import { ArrowLeft, Clock, CheckCircle, Lock, Play, BookOpen } from "lucide-react";
import { motion } from "motion/react";
import { lessons } from "../data";

interface ChapterDetailProps {
  chapter: { id: number; title: string; icon: string; color: string; bgColor: string; description: string; lessons: number; progress: number };
  onBack: () => void;
  onLesson: (lesson: unknown) => void;
}

const statusConfig = {
  completed: { icon: CheckCircle, color: "#22C55E", bg: "#DCFCE7", label: "Hoàn thành" },
  "in-progress": { icon: Play, color: "#2563EB", bg: "#DBEAFE", label: "Đang học" },
  locked: { icon: Lock, color: "#94A3B8", bg: "#F1F5F9", label: "Chưa mở" },
};

export function ChapterDetail({ chapter, onBack, onLesson }: ChapterDetailProps) {
  const chapterLessons = lessons.filter((l) => l.chapterId === chapter.id);
  const completed = chapterLessons.filter((l) => l.status === "completed").length;

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div
        className="pt-12 pb-6 px-5"
        style={{ background: `linear-gradient(135deg, ${chapter.color}, ${chapter.color}cc)` }}
      >
        <button
          onClick={onBack}
          className="flex items-center gap-1.5 text-white/80 mb-4 active:opacity-60"
        >
          <ArrowLeft size={18} />
          <span className="text-sm font-semibold">Quay lại</span>
        </button>
        <div className="flex items-center gap-3">
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl"
            style={{ backgroundColor: "rgba(255,255,255,0.15)" }}
          >
            {chapter.icon}
          </div>
          <div>
            <h1 className="text-white font-black text-lg">{chapter.title}</h1>
            <p className="text-white/70 text-xs mt-0.5">{chapter.description}</p>
          </div>
        </div>
        <div className="mt-4 flex items-center gap-3">
          <div className="flex-1 h-2 bg-white/20 rounded-full overflow-hidden">
            <div
              className="h-full bg-secondary rounded-full transition-all"
              style={{ width: `${chapter.progress}%` }}
            />
          </div>
          <span className="text-white font-black text-sm">{completed}/{chapterLessons.length}</span>
        </div>
      </div>

      {/* Lessons */}
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-6 scrollbar-hide">
        <div className="flex items-center gap-2 mb-4">
          <BookOpen size={16} className="text-muted-foreground" />
          <span className="text-foreground font-black text-sm">Danh sách bài học</span>
        </div>

        <div className="flex flex-col gap-3">
          {chapterLessons.map((lesson, i) => {
            const cfg = statusConfig[lesson.status];
            const Icon = cfg.icon;
            const isLocked = lesson.status === "locked";

            return (
              <motion.div
                key={lesson.id}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.08 }}
                onClick={() => !isLocked && onLesson(lesson)}
                className={`bg-card rounded-2xl p-4 border border-border shadow-sm transition-transform ${
                  isLocked ? "opacity-60" : "active:scale-[0.98] cursor-pointer"
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center text-xl shrink-0"
                    style={{ backgroundColor: chapter.bgColor }}
                  >
                    {lesson.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-foreground font-black text-sm truncate">{lesson.title}</p>
                    <div className="flex items-center gap-2 mt-0.5">
                      <Clock size={11} className="text-muted-foreground" />
                      <span className="text-muted-foreground text-xs">{lesson.duration} phút</span>
                      {lesson.score !== null && (
                        <>
                          <span className="text-muted-foreground">·</span>
                          <span className="text-xs font-black" style={{ color: "#22C55E" }}>
                            {lesson.score}/10
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                  <div
                    className="shrink-0 flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-black"
                    style={{ backgroundColor: cfg.bg, color: cfg.color }}
                  >
                    <Icon size={11} strokeWidth={2.5} fill={lesson.status === "in-progress" ? "currentColor" : "none"} />
                    {lesson.status === "completed" ? "Học lại" : lesson.status === "in-progress" ? "Học tiếp" : "Khóa"}
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
