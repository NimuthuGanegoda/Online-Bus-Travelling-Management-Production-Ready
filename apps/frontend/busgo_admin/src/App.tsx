import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import AdminLayout from './layouts/AdminLayout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import FleetMap from './pages/FleetMap';
import Emergencies from './pages/Emergencies';
import FleetMgmt from './pages/FleetMgmt';
import UserManagement from './pages/UserManagement';
import AuditLogs from './pages/AuditLogs';
import RoutesPage from './pages/RoutesPage';
import Payments from './pages/Payments';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <>{children}</> : <Navigate to="/admin/login" replace />;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/admin/login" element={<Login />} />
      <Route
        path="/admin"
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route path="dashboard"  element={<Dashboard />} />
        <Route path="fleet-map"  element={<FleetMap />} />
        <Route path="emergencies" element={<Emergencies />} />
        <Route path="fleet"      element={<FleetMgmt />} />
        <Route path="users"      element={<UserManagement />} />
        <Route path="audit-logs" element={<AuditLogs />} />
        <Route path="routes"     element={<RoutesPage />} />
        <Route path="payments"   element={<Payments />} />
        <Route index             element={<Navigate to="dashboard" replace />} />
      </Route>
      <Route path="*" element={<Navigate to="/admin/login" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
