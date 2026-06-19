import { useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { MobileFrame } from "./components/MobileFrame";
import { AdminPanel } from "./admin/AdminPanel";
import { Splash } from "./screens/Splash";
import { Login } from "./screens/Login";
import { Register } from "./screens/Register";
import { Home } from "./screens/Home";
import { ChapterDetail } from "./screens/ChapterDetail";
import { LessonView } from "./screens/LessonView";
import { Quiz } from "./screens/Quiz";
import { QuizResult } from "./screens/QuizResult";
import { Progress } from "./screens/Progress";
import { Profile } from "./screens/Profile";
import { OfflineLessons } from "./screens/OfflineLessons";

type Screen =
  | "splash"
  | "login"
  | "register"
  | "home"
  | "chapter"
  | "lesson"
  | "quiz"
  | "result"
  | "progress"
  | "profile"
  | "offline";

interface AppState {
  screen: Screen;
  chapter?: unknown;
  lesson?: unknown;
  quizScore?: number;
  quizAnswers?: number[];
}

function ScreenWrapper({ children, id }: { children: React.ReactNode; id: string }) {
  return (
    <motion.div
      key={id}
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.2 }}
      className="h-full"
    >
      {children}
    </motion.div>
  );
}

export default function App() {
  const [isAdmin, setIsAdmin] = useState(false);
  const [state, setState] = useState<AppState>({ screen: "splash" });

  const go = (screen: Screen, extra?: Partial<AppState>) => {
    setState((prev) => ({ ...prev, screen, ...extra }));
  };

  const navigate = (screenKey: string, data?: unknown) => {
    if (screenKey === "home") go("home");
    else if (screenKey === "chapters") go("home");
    else if (screenKey === "progress") go("progress");
    else if (screenKey === "profile") go("profile");
    else if (screenKey === "offline") go("offline");
    else if (screenKey === "chapter") go("chapter", { chapter: data });
    else if (screenKey === "lesson") go("lesson", { lesson: data });
  };

  const { screen } = state;

  if (isAdmin) {
    return <AdminPanel onExit={() => setIsAdmin(false)} />;
  }

  return (
    <MobileFrame>
      {/* Admin entry button */}
      <div className="absolute top-3 right-3 z-[100]">
        <button
          onClick={() => setIsAdmin(true)}
          className="text-[9px] font-black px-2 py-1 bg-slate-800/70 text-slate-300 rounded-lg hover:bg-slate-700 transition backdrop-blur"
        >
          Admin ⚙️
        </button>
      </div>
      <div className="h-full relative overflow-hidden" style={{ fontFamily: "'Nunito', 'Inter', sans-serif" }}>
        <AnimatePresence mode="wait">
          {screen === "splash" && (
            <ScreenWrapper id="splash">
              <Splash onStart={() => go("login")} />
            </ScreenWrapper>
          )}
          {screen === "login" && (
            <ScreenWrapper id="login">
              <Login onLogin={() => go("home")} onRegister={() => go("register")} />
            </ScreenWrapper>
          )}
          {screen === "register" && (
            <ScreenWrapper id="register">
              <Register onRegister={() => go("home")} onLogin={() => go("login")} />
            </ScreenWrapper>
          )}
          {screen === "home" && (
            <ScreenWrapper id="home">
              <Home onNavigate={navigate} />
            </ScreenWrapper>
          )}
          {screen === "chapter" && state.chapter && (
            <ScreenWrapper id="chapter">
              <ChapterDetail
                chapter={state.chapter as Parameters<typeof ChapterDetail>[0]["chapter"]}
                onBack={() => go("home")}
                onLesson={(lesson) => go("lesson", { lesson })}
              />
            </ScreenWrapper>
          )}
          {screen === "lesson" && state.lesson && (
            <ScreenWrapper id="lesson">
              <LessonView
                lesson={state.lesson as Parameters<typeof LessonView>[0]["lesson"]}
                onBack={() => go("chapter")}
                onQuiz={() => go("quiz")}
              />
            </ScreenWrapper>
          )}
          {screen === "quiz" && (
            <ScreenWrapper id="quiz">
              <Quiz
                onResult={(score, answers) => go("result", { quizScore: score, quizAnswers: answers })}
                onBack={() => go("lesson")}
              />
            </ScreenWrapper>
          )}
          {screen === "result" && (
            <ScreenWrapper id="result">
              <QuizResult
                score={state.quizScore ?? 0}
                answers={state.quizAnswers ?? []}
                onHome={() => go("home")}
                onNext={() => go("home")}
              />
            </ScreenWrapper>
          )}
          {screen === "progress" && (
            <ScreenWrapper id="progress">
              <Progress onNavigate={navigate} />
            </ScreenWrapper>
          )}
          {screen === "profile" && (
            <ScreenWrapper id="profile">
              <Profile onNavigate={navigate} onLogout={() => go("login")} />
            </ScreenWrapper>
          )}
          {screen === "offline" && (
            <ScreenWrapper id="offline">
              <OfflineLessons onBack={() => go("profile")} />
            </ScreenWrapper>
          )}
        </AnimatePresence>
      </div>
    </MobileFrame>
  );
}
