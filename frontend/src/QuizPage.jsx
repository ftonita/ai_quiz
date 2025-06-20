import React, { useEffect, useState } from 'react';

function QuizPage({ user, token }) {
  const [question, setQuestion] = useState(null);
  const [selected, setSelected] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [answered, setAnswered] = useState(false);
  const [timer, setTimer] = useState(0);
  const [result, setResult] = useState(null);
  const [showResult, setShowResult] = useState(false);
  const [score, setScore] = useState(0);
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [questionCount, setQuestionCount] = useState(0);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // Проверяем аутентификацию
  useEffect(() => {
    setIsAuthenticated(!!token && !!user);
  }, [token, user]);

  // Функция для получения вопроса
  const fetchQuestion = async () => {
    try {
      const response = await fetch('/api/room/question');
      const q = await response.json();
      if (q.question) {
        setQuestion(q.question);
        setSelected(null);
        setSubmitting(false);
        setAnswered(false);
        setResult(null);
        setShowResult(false);
      }
    } catch (error) {
      console.error('Error fetching question:', error);
    }
  };

  // Функция для получения результатов
  const fetchResults = async () => {
    try {
      const response = await fetch('/api/room/leaderboard');
      const results = await response.json();
      const userResult = results.find(r => r.name === user);
      if (userResult) {
        setScore(userResult.score);
      }
    } catch (error) {
      console.error('Error fetching results:', error);
    }
  };

  useEffect(() => {
    let ws = new WebSocket('ws://localhost:8000/ws/room');
    
    ws.onopen = () => {
      console.log('WebSocket connected in QuizPage');
    };
    
    ws.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        setTimer(data.timer);
        setCurrentQuestion(data.current_question || 0);
        setQuestionCount(data.question_count || 0);
        
        // Если стадия изменилась на quiz, обновляем вопрос
        if (data.stage === 'quiz') {
          fetchQuestion();
        }
        
        // Если стадия изменилась на pause, показываем результаты
        if (data.stage === 'pause') {
          setShowResult(true);
          fetchResults();
        }
      } catch (error) {
        console.error('WebSocket message error:', error);
      }
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error in QuizPage:', error);
    };
    
    ws.onclose = () => {
      console.log('WebSocket disconnected in QuizPage');
    };
    
    return () => ws.close();
  }, [user]);

  // Получаем первый вопрос при загрузке
  useEffect(() => {
    fetchQuestion();
  }, []);

  const handleAnswer = async (idx) => {
    if (submitting || answered || !isAuthenticated) return;
    
    setSelected(idx);
    setSubmitting(true);
    
    try {
      const res = await fetch('/api/room/answer', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ answer: idx })
      });
      
      if (res.ok) {
        setResult('Ответ принят!');
        setAnswered(true);
        setSubmitting(false);
        // Обновляем результаты
        fetchResults();
      } else {
        const data = await res.json();
        setResult(data.detail || 'Ошибка');
        setSubmitting(false);
        setSelected(null);
      }
    } catch (error) {
      console.error('Error submitting answer:', error);
      setResult('Ошибка подключения');
      setSubmitting(false);
      setSelected(null);
    }
  };

  if (!question || !question.text)
    return (
      <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif', fontSize: 22, textAlign: 'center' }}>
        Ожидание вопроса...
      </div>
    );

  return (
    <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <div style={{ fontSize: 16, color: '#888', marginBottom: 8 }}>
        Вопрос {currentQuestion + 1} из {questionCount}
      </div>
      <div style={{ fontSize: 18, color: '#888', marginBottom: 8 }}>{question.theme}</div>
      <div style={{ fontSize: 24, fontWeight: 700, marginBottom: 16 }}>{question.text}</div>
      <div style={{ fontSize: 32, fontWeight: 700, marginBottom: 24 }}>
        ⏰ {timer} сек
      </div>
      
      {!isAuthenticated && (
        <div style={{ 
          background: '#fff3cd', 
          border: '1px solid #ffeaa7', 
          borderRadius: 8, 
          padding: 16, 
          marginBottom: 16,
          textAlign: 'center',
          color: '#856404'
        }}>
          ⚠️ Вы не зарегистрированы. Можете смотреть вопросы, но не можете отвечать.
        </div>
      )}
      
      <div>
        {question.options.map((opt, i) => {
          const isSelected = selected === i;
          const isDisabled = submitting || answered || !isAuthenticated;
          const isCorrect = answered && isSelected;
          
          return (
            <button
              key={i}
              onClick={() => handleAnswer(i)}
              disabled={isDisabled}
              style={{
                display: 'block',
                width: '100%',
                marginBottom: 12,
                padding: 16,
                fontSize: 18,
                borderRadius: 8,
                border: isSelected ? '2px solid #007bff' : '1px solid #ccc',
                background: isSelected ? '#e6f0ff' : '#fff',
                color: '#222',
                cursor: isDisabled ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                opacity: isDisabled && !isSelected ? 0.6 : 1,
                transform: isSelected ? 'scale(1.02)' : 'scale(1)'
              }}
            >
              {opt}
              {submitting && isSelected && ' ✓'}
            </button>
          );
        })}
      </div>
      {result && (
        <div style={{ marginTop: 16, fontSize: 18, color: '#007bff', textAlign: 'center' }}>
          {result}
        </div>
      )}
      {showResult && isAuthenticated && (
        <div style={{ marginTop: 8, fontSize: 18, color: '#007bff', textAlign: 'center' }}>
          Ваши баллы: {score}
        </div>
      )}
      <div style={{ fontSize: 13, color: '#888', marginTop: 16, textAlign: 'center' }}>
        {isAuthenticated ? 'Если не ответите — 0 баллов' : 'Зарегистрируйтесь, чтобы участвовать'}
      </div>
    </div>
  );
}

export default QuizPage; 