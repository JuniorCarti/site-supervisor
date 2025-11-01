import { createContext, useState, useEffect } from 'react';
import { jwtDecode } from 'jwt-decode';
import axiosInstance from '../api/axios';

export const AuthContext = createContext();

const normalizeRole = (role) => {
  if (!role) return role;
  const r = String(role).toLowerCase();
  if (r === 'admin') return 'Admin';
  if (r === 'manager') return 'Manager';
  if (r === 'driver') return 'Driver';
  return role;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

useEffect(() => {
  const token = localStorage.getItem('access_token');
  const savedUser = localStorage.getItem('user');
  
  if (token && savedUser) {
    try {
      const decoded = jwtDecode(token);
      if (decoded.exp * 1000 > Date.now()) {
        const parsed = JSON.parse(savedUser);
        const normalized = { ...parsed, role: normalizeRole(parsed.role) };
        // Persist normalized role if it changed
        if (normalized.role !== parsed.role) {
          localStorage.setItem('user', JSON.stringify(normalized));
        }
        setUser(normalized);
      } else {
        logout();
      }
    } catch (error) {
      logout();
    }
  }
  setLoading(false);
}, []);

const login = async (email, password) => {
  try {
    const response = await axiosInstance.post('/auth/login', { email, password });
    const { access_token, user: userData } = response.data;
    
    const normalizedUser = { ...userData, role: normalizeRole(userData.role) };
    localStorage.setItem('token', access_token);
    localStorage.setItem('user', JSON.stringify(normalizedUser));
    setUser(normalizedUser);
    
    return { success: true, user: normalizedUser };
  } catch (error) {
    return { 
      success: false, 
      error: error.response?.data?.error || 'Login failed' 
    };
  }
};

  const register = async (userData) => {
    try {
      const response = await axiosInstance.post('/auth/register', userData);
      return { success: true, data: response.data };
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.error || 'Registration failed' 
      };
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
  };

  const value = {
    user,
    login,
    register,
    logout,
    loading,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
