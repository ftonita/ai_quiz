import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

function validateName(name) {
  // Поддерживаем латиницу, кириллицу, цифры, пробелы и точки
  return /^[a-zA-Zа-яА-Я0-9 .]+$/.test(name.trim()) && name.trim().length > 0;
}

function RegisterPage({ setUser, setToken }) {
  const [name, setName] = useState('');
  const [valid, setValid] = useState(false);
  const [error, setError] = useState('');
  const [registered, setRegistered] = useState(false);
  const [closed, setClosed] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    setValid(validateName(name));
    setError(!validateName(name) && name ? 'Имя невалидно' : '');
  }, [name]);

  useEffect(() => {
    fetch('/api/room')
      .then(r => r.json())
      .then(data => {
        if (data.stage !== 'registration' || data.timer <= 0) setClosed(true);
      })
      .catch(err => {
        console.error('Error fetching room status:', err);
        setError('Ошибка подключения к серверу');
      });
  }, []);

  const handleRegister = async () => {
    if (!valid || loading) return;
    
    setLoading(true);
    setError('');
    
    try {
      const res = await fetch('/api/room/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name.trim() })
      });
      
      if (res.ok) {
        const data = await res.json();
        setRegistered(true);
        
        // Сохраняем токен и пользователя
        localStorage.setItem('quiz_token', data.token);
        localStorage.setItem('quiz_user', data.user);
        
        if (typeof setUser === 'function') setUser(data.user);
        if (typeof setToken === 'function') setToken(data.token);
        
        // Перенаправляем на главную страницу через небольшую задержку
        setTimeout(() => {
          navigate('/room');
        }, 1000);
      } else {
        const data = await res.json();
        setError(data.detail || 'Ошибка регистрации');
      }
    } catch (err) {
      console.error('Registration error:', err);
      setError('Ошибка подключения к серверу');
    } finally {
      setLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && valid && !loading) {
      handleRegister();
    }
  };

  if (closed)
    return (
      <div style={{ maxWidth: 400, margin: '40px auto', fontFamily: 'sans-serif', fontSize: 20, textAlign: 'center' }}>
        Извините, регистрация уже завершена
      </div>
    );
    
  if (registered)
    return (
      <div style={{ maxWidth: 400, margin: '40px auto', fontFamily: 'sans-serif', fontSize: 20, textAlign: 'center' }}>
        Вы зарегистрированы!<br />
        Перенаправляем на главную страницу...
      </div>
    );

  return (
    <div style={{ maxWidth: 400, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h2>Регистрация</h2>
      <input
        type="text"
        value={name}
        onChange={e => setName(e.target.value)}
        onKeyPress={handleKeyPress}
        placeholder="Ваше имя"
        disabled={loading}
        style={{ 
          fontSize: 18, 
          padding: 8, 
          width: '100%', 
          marginBottom: 8, 
          borderRadius: 4, 
          border: '1px solid #ccc',
          boxSizing: 'border-box'
        }}
      />
      <button
        onClick={handleRegister}
        disabled={!valid || loading}
        style={{
          width: '100%',
          padding: 12,
          fontSize: 18,
          borderRadius: 4,
          border: 'none',
          background: valid && !loading ? '#007bff' : '#ccc',
          color: '#fff',
          cursor: valid && !loading ? 'pointer' : 'not-allowed',
          marginBottom: 8,
          boxSizing: 'border-box'
        }}
      >
        {loading ? 'Регистрация...' : 'Зарегистрироваться'}
      </button>
      {error && <div style={{ color: 'red', fontSize: 14, marginBottom: 8 }}>{error}</div>}
      <div style={{ fontSize: 13, color: '#888', marginTop: 8 }}>
        Имя: буквы любого алфавита, цифры, пробел, точка
      </div>
    </div>
  );
}

export default RegisterPage; 