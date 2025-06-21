import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import RoomPage from './RoomPage';
import RegisterPage from './RegisterPage';
import QuizPage from './QuizPage';
import ResultsPage from './ResultsPage';
import DuckBackground from './DuckBackground';

// Компонент для автоматического перенаправления
function AutoRedirect({ user, roomStage, isLoading }) {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    // Не перенаправляем, пока данные загружаются
    if (isLoading) return;

    const getTargetRoute = () => {
      if (roomStage === 'registration') {
        return user ? '/room' : '/room/register';
      } else if (roomStage === 'preparation') {
        return '/room';
      } else if (roomStage === 'quiz') {
        return '/room/quiz';
      } else if (roomStage === 'results') {
        return '/room/results';
      } else if (roomStage === 'waiting') {
        return '/room';
      }
      return '/room';
    };

    const targetRoute = getTargetRoute();
    if (location.pathname !== targetRoute) {
      navigate(targetRoute, { replace: true });
    }
  }, [roomStage, user, location.pathname, navigate, isLoading]);

  return null;
}

function App() {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [roomStage, setRoomStage] = useState('registration');
  const [isLoading, setIsLoading] = useState(true);

  // Проверка валидности токена
  const validateToken = async (token) => {
    try {
      const response = await fetch('/api/room/me', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      return response.ok;
    } catch (error) {
      return false;
    }
  };

  // Загружаем сохраненные данные при старте
  useEffect(() => {
    const loadSavedData = async () => {
      const savedUser = localStorage.getItem('quiz_user');
      const savedToken = localStorage.getItem('quiz_token');
      
      if (savedUser && savedToken) {
        // Проверяем валидность токена
        const isValid = await validateToken(savedToken);
        if (isValid) {
          setUser(savedUser);
          setToken(savedToken);
        } else {
          // Токен недействителен, очищаем
          localStorage.removeItem('quiz_user');
          localStorage.removeItem('quiz_token');
        }
      }
      setIsLoading(false);
    };

    loadSavedData();
  }, []);

  // Функция для выхода
  const handleLogout = () => {
    localStorage.removeItem('quiz_user');
    localStorage.removeItem('quiz_token');
    setUser(null);
    setToken(null);
  };

  // Получаем информацию о комнате
  useEffect(() => {
    const fetchRoomInfo = async () => {
      try {
        const response = await fetch('/api/room');
        const data = await response.json();
        
        // Если переходим к стадии "waiting", сбрасываем данные пользователя
        if (data.stage === 'waiting' && roomStage !== 'waiting') {
          localStorage.removeItem('quiz_user');
          localStorage.removeItem('quiz_token');
          setUser(null);
          setToken(null);
        }
        
        setRoomStage(data.stage);
      } catch (error) {
        console.error('Error fetching room info:', error);
      }
    };

    fetchRoomInfo();
    const interval = setInterval(fetchRoomInfo, 1000);
    return () => clearInterval(interval);
  }, [roomStage]);

  // Показываем загрузку
  if (isLoading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontFamily: 'sans-serif'
      }}>
        Загрузка...
      </div>
    );
  }

  return (
    <Router>
      <div className="App">
        <DuckBackground />
        <AutoRedirect user={user} roomStage={roomStage} isLoading={isLoading} />
        <Routes>
          <Route path="/" element={<Navigate to="/room" replace />} />
          
          <Route 
            path="/room" 
            element={
              <RoomPage 
                user={user} 
                token={token} 
                onLogout={handleLogout}
              />
            } 
          />
          
          <Route 
            path="/room/register" 
            element={
              <RegisterPage 
                setUser={setUser} 
                setToken={setToken}
              />
            } 
          />
          
          <Route 
            path="/room/quiz" 
            element={
              <QuizPage 
                user={user} 
                token={token}
              />
            } 
          />
          
          <Route 
            path="/room/results" 
            element={
              <ResultsPage />
            } 
          />
          
          <Route path="*" element={<Navigate to="/room" replace />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App; 