import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

function RoomPage({ user, token, onLogout }) {
  const [data, setData] = useState({ stage: '', timer: 0, users: [] });
  const [qr, setQr] = useState(null);
  const [questionInfo, setQuestionInfo] = useState({ current: 0, total: 0 });
  const [wsConnected, setWsConnected] = useState(false);
  const navigate = useNavigate();

  // Fallback функция для получения данных через API
  const fetchData = async () => {
    try {
      const response = await fetch('/api/room');
      const d = await response.json();
      setData(d);
      setQuestionInfo({ current: (d.current_question || 0) + 1, total: d.question_count || 0 });
    } catch (error) {
      console.error('API fetch error:', error);
    }
  };

  useEffect(() => {
    // Сначала получаем данные через API
    fetchData();
    
    // Затем подключаем WebSocket
    const ws = new WebSocket('ws://localhost:8000/ws/room');
    
    ws.onopen = () => {
      console.log('WebSocket connected');
      setWsConnected(true);
    };
    
    ws.onmessage = (e) => {
      try {
        const d = JSON.parse(e.data);
        setData(d);
        setQuestionInfo({ current: (d.current_question || 0) + 1, total: d.question_count || 0 });
      } catch (error) {
        console.error('WebSocket message error:', error);
      }
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
      setWsConnected(false);
    };
    
    ws.onclose = () => {
      console.log('WebSocket disconnected');
      setWsConnected(false);
    };
    
    return () => ws.close();
  }, []);

  // Дополнительное обновление данных каждую секунду для таймера
  useEffect(() => {
    const interval = setInterval(fetchData, 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (data.stage === 'registration' && !qr) {
      fetch('/api/room/qr')
        .then(r => r.blob())
        .then(blob => {
          setQr(URL.createObjectURL(blob));
        })
        .catch(error => {
          console.error('QR fetch error:', error);
        });
    }
    if (data.stage !== 'registration') setQr(null);
  }, [data.stage]);

  // Форматирование времени
  const formatTime = (seconds) => {
    if (seconds <= 0) return '0 сек';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (mins > 0) {
      return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
    return `${secs} сек`;
  };

  return (
    <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h1>AI Quiz</h1>
      
      {/* Информация о пользователе */}
      {user && data.stage !== 'waiting' && (
        <div style={{ 
          background: '#e8f5e8', 
          border: '1px solid #4caf50', 
          borderRadius: 8, 
          padding: 12, 
          marginBottom: 16,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <span>👤 {user}</span>
          <button
            onClick={onLogout}
            style={{
              background: '#f44336',
              color: 'white',
              border: 'none',
              borderRadius: 4,
              padding: '4px 8px',
              fontSize: 12,
              cursor: 'pointer'
            }}
          >
            Выйти
          </button>
        </div>
      )}
      
      {!wsConnected && (
        <div style={{ color: 'orange', fontSize: 14, marginBottom: 8 }}>
          ⚠️ WebSocket не подключен, используем API
        </div>
      )}
      
      <div style={{ fontSize: 24, marginBottom: 16 }}>
        {data.stage === 'registration' && 'Регистрация'}
        {data.stage === 'preparation' && <span style={{ color: '#007bff', fontWeight: 700, fontSize: 32, letterSpacing: 2, animation: 'blink 1s infinite alternate' }}>Приготовьтесь...</span>}
        {data.stage === 'quiz' && 'Викторина'}
        {data.stage === 'results' && 'Результаты'}
        {data.stage === 'waiting' && <span style={{ color: '#ff9800', fontWeight: 700, fontSize: 28 }}>Ожидание новой викторины...</span>}
      </div>
      
      <div style={{ fontSize: 32, fontWeight: 700, marginBottom: 24 }}>
        {data.timer > 0 && <span>⏰ {formatTime(data.timer)}</span>}
      </div>
      
      {qr && (
        <div style={{ marginBottom: 24 }}>
          <img src={qr} alt="QR for registration" style={{ width: 200, height: 200 }} />
          <div style={{ fontSize: 14, color: '#888' }}>Сканируйте для регистрации</div>
        </div>
      )}
      
      <div style={{ background: '#f5f5f5', borderRadius: 8, padding: 16 }}>
        <div style={{ fontWeight: 600, marginBottom: 8 }}>
          Участники ({data.users.length})
        </div>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {data.users.map((u, i) => (
            <li key={i} style={{ padding: '2px 0' }}>
              {u} {u === user && '👤'}
            </li>
          ))}
        </ul>
      </div>
      
      {data.stage === 'registration' && !user && (
        <button
          style={{ margin: '16px 0', padding: '12px 24px', fontSize: 18, borderRadius: 6, background: '#007bff', color: '#fff', border: 'none', cursor: 'pointer' }}
          onClick={() => navigate('/room/register')}
        >
          Зарегистрироваться
        </button>
      )}
      
      {data.stage === 'waiting' && (
        <div style={{ 
          background: '#fff3e0', 
          border: '1px solid #ffb74d', 
          borderRadius: 8, 
          padding: 16, 
          margin: '16px 0',
          textAlign: 'center',
          color: '#e65100'
        }}>
          ⏳ Новая викторина начнется через {formatTime(data.timer)}
        </div>
      )}
      
      {data.stage === 'registration' && data.timer === 0 && (
        <div style={{ color: 'red', fontSize: 18, margin: '16px 0' }}>
          Регистрация завершена
        </div>
      )}
      
      {data.stage === 'quiz' && (
        <div style={{ fontSize: 18, color: '#007bff', marginBottom: 8 }}>
          Вопрос {questionInfo.current} из {questionInfo.total}
        </div>
      )}
      
      <style>{`@keyframes blink { 0% { opacity: 1; } 100% { opacity: 0.5; } }`}</style>
    </div>
  );
}

export default RoomPage; 