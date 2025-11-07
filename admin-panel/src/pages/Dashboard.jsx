import { useQuery } from "@tanstack/react-query";
import axios from "axios";
import { API_BASE_URL } from "../config/api";
import { useNavigate } from "react-router-dom";
import { useState, useEffect } from "react";
import "../styles/dashboard-animations.css";
import {
  Users,
  Phone,
  TrendingUp,
  Activity,
  Zap,
  Target,
  Award,
  Clock,
  UserCheck,
  PhoneCall,
  PhoneIncoming,
  PhoneMissed,
  Calendar,
  BarChart3,
  Sparkles,
  Crown,
  CheckCircle2,
  XCircle,
  AlertCircle,
  Timer,
  Briefcase,
  Shield,
  ArrowUpRight,
  ArrowDownRight,
  TrendingDown,
  MousePointer2,
  ExternalLink,
} from "lucide-react";
import {
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  AreaChart,
  Area,
  LineChart,
  Line,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from "recharts";

const Dashboard = () => {
  const navigate = useNavigate();
  const [notification, setNotification] = useState(null);
  const [hoveredCard, setHoveredCard] = useState(null);
  const [demoMode, setDemoMode] = useState(false);

  const {
    data: stats,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ["dashboard-stats"],
    queryFn: async () => {
      const response = await axios.get(
        `${API_BASE_URL}/admin_dashboard_stats.php`
      );
      console.log("API Response:", response.data);

      // Handle different response structures
      if (response.data && response.data.success && response.data.data) {
        return response.data.data;
      }

      // If data is directly in response
      if (response.data && !response.data.success) {
        return response.data;
      }

      // Return empty object as fallback
      return {
        total_telecallers: 0,
        total_managers: 0,
        total_drivers: 0,
        total_calls: 0,
        connected_calls: 0,
        calls_today: 0,
        active_calls: 0,
        conversion_rate: 0,
        call_trends: [],
        call_distribution: [],
        top_performers: [],
        recent_activity: [],
        telecallers_list: [],
        managers_list: [],
        total_admins: 0,
      };
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  // Navigation handlers for KPI cards
  const handleKPIClick = (type, value) => {
    console.log(`KPI clicked: ${type} with value: ${value}`);

    // Add haptic feedback (if supported)
    if (navigator.vibrate) {
      navigator.vibrate(50);
    }

    // Show notification with enhanced messaging
    const typeDisplayName = type
      .replace(/_/g, " ")
      .replace(/\b\w/g, (l) => l.toUpperCase());
    setNotification({
      type: "info",
      message: `Opening ${typeDisplayName} (${value})`,
      value: value,
    });

    // Clear notification after 3 seconds
    setTimeout(() => setNotification(null), 3000);

    switch (type) {
      case "telecallers":
        navigate("/telecallers");
        break;
      case "active_calls":
        navigate("/calls", { state: { filter: "active" } });
        break;
      case "calls_today":
        navigate("/calls", { state: { filter: "today" } });
        break;
      case "conversion_rate":
        navigate("/analytics", { state: { focus: "conversion" } });
        break;
      case "drivers":
        navigate("/drivers");
        break;
      case "managers":
        navigate("/managers");
        break;
      case "connected_calls":
        navigate("/calls", { state: { filter: "connected" } });
        break;
      case "admins":
        navigate("/admins");
        break;
      default:
        console.log(`No navigation defined for: ${type}`);
        setNotification({
          type: "warning",
          message: `Navigation for ${typeDisplayName} coming soon!`,
          value: value,
        });
    }
  };

  const COLORS = [
    "#6366f1",
    "#8b5cf6",
    "#ec4899",
    "#f59e0b",
    "#10b981",
    "#06b6d4",
    "#f43f5e",
  ];

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="relative">
          <div className="w-20 h-20 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
            <Zap className="w-8 h-8 text-indigo-500 animate-pulse" />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white p-6">
        <div className="text-center">
          <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Activity className="w-10 h-10 text-red-500" />
          </div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            Failed to Load Dashboard
          </h2>
          <p className="text-gray-600 mb-4">Error: {error.message}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  const statCards = [
    {
      title: "Total Telecallers",
      value: stats?.total_telecallers || 0,
      change: "+12%",
      icon: Users,
      gradient: "from-indigo-500 to-purple-600",
      iconBg: "bg-gradient-to-br from-indigo-500 to-purple-600",
      bgAccent: "bg-indigo-50",
      trend: "up",
      type: "telecallers",
      description: "Active telecaller accounts",
    },
    {
      title: "Active Calls",
      value: stats?.active_calls || 0,
      change: "Live",
      icon: Phone,
      gradient: "from-emerald-500 to-teal-600",
      iconBg: "bg-gradient-to-br from-emerald-500 to-teal-600",
      bgAccent: "bg-emerald-50",
      trend: "up",
      type: "active_calls",
      description: "Currently ongoing calls",
    },
    {
      title: "Calls Today",
      value: stats?.calls_today || 0,
      change: "+8%",
      icon: Activity,
      gradient: "from-blue-500 to-cyan-600",
      iconBg: "bg-gradient-to-br from-blue-500 to-cyan-600",
      bgAccent: "bg-blue-50",
      trend: "up",
      type: "calls_today",
      description: "Total calls made today",
    },
    {
      title: "Conversion Rate",
      value: `${stats?.conversion_rate || 0}%`,
      change: "+2.5%",
      icon: TrendingUp,
      gradient: "from-orange-500 to-pink-600",
      iconBg: "bg-gradient-to-br from-orange-500 to-pink-600",
      bgAccent: "bg-orange-50",
      trend: "up",
      type: "conversion_rate",
      description: "Call success percentage",
    },
  ];

  const secondaryStatCards = [
    {
      title: "Total Drivers",
      value: stats?.total_drivers || 0,
      icon: Target,
      gradient: "from-blue-500 to-cyan-600",
      type: "drivers",
      label: "Database",
      description: "Registered drivers in system",
    },
    {
      title: "Total Managers",
      value: stats?.total_managers || 0,
      icon: Shield,
      gradient: "from-purple-500 to-pink-600",
      type: "managers",
      label: "Active",
      description: "Management team members",
    },
    {
      title: "Connected Calls",
      value: stats?.connected_calls || 0,
      icon: PhoneCall,
      gradient: "from-emerald-500 to-teal-600",
      type: "connected_calls",
      label: "Success Rate",
      description: "Successfully connected calls",
    },
    {
      title: "Total Admins",
      value: stats?.total_admins || 0,
      icon: Users,
      gradient: "from-amber-500 to-orange-600",
      type: "admins",
      label: "System",
      description: "System administrators",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-50 p-6">
      {/* Elegant Background Pattern */}
      <div className="fixed inset-0 bg-[radial-gradient(circle_at_20%_30%,rgba(99,102,241,0.03),transparent_40%),radial-gradient(circle_at_80%_70%,rgba(139,92,246,0.03),transparent_40%),radial-gradient(circle_at_50%_50%,rgba(236,72,153,0.02),transparent_50%)] pointer-events-none"></div>
      <div className="fixed inset-0 bg-[linear-gradient(to_right,#80808008_1px,transparent_1px),linear-gradient(to_bottom,#80808008_1px,transparent_1px)] bg-[size:64px_64px] pointer-events-none"></div>

      <div className="relative z-10 max-w-[1800px] mx-auto">
        {/* Premium Header */}
        <div className="bg-white rounded-3xl p-8 mb-8 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all duration-300">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-4">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl blur-xl opacity-30 animate-pulse"></div>
                <div className="relative bg-gradient-to-br from-indigo-500 to-purple-600 p-3.5 rounded-2xl shadow-lg">
                  <Sparkles className="w-9 h-9 text-white" />
                </div>
              </div>
              <div>
                <h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 bg-clip-text text-transparent mb-1">
                  Dashboard Overview
                </h1>
                <p className="text-gray-500 text-base font-medium">
                  Real-time business intelligence & analytics
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <button
                onClick={() => {
                  setDemoMode(!demoMode);
                  setNotification({
                    type: demoMode ? "info" : "success",
                    message: demoMode
                      ? "Demo mode disabled"
                      : "Demo mode enabled - All cards are highlighted!",
                    value: demoMode ? "OFF" : "ON",
                  });
                  setTimeout(() => setNotification(null), 3000);
                }}
                className={`flex items-center gap-2 px-4 py-2.5 rounded-full border shadow-sm transition-all duration-200 hover:shadow-md ${
                  demoMode
                    ? "bg-gradient-to-r from-amber-50 to-orange-50 hover:from-amber-100 hover:to-orange-100 border-amber-200/50 text-amber-700"
                    : "bg-gradient-to-r from-gray-50 to-gray-100 hover:from-gray-100 hover:to-gray-200 border-gray-200/50 text-gray-700"
                }`}
                title="Highlight Clickable Cards"
              >
                <Sparkles
                  className={`w-4 h-4 ${demoMode ? "animate-pulse" : ""}`}
                />
                <span className="font-semibold text-sm">
                  {demoMode ? "Demo On" : "Demo"}
                </span>
              </button>
              <button
                onClick={() => refetch()}
                className="flex items-center gap-2 bg-gradient-to-r from-indigo-50 to-purple-50 hover:from-indigo-100 hover:to-purple-100 px-4 py-2.5 rounded-full border border-indigo-200/50 shadow-sm transition-all duration-200 hover:shadow-md"
                title="Refresh Dashboard"
              >
                <Activity
                  className={`w-4 h-4 text-indigo-600 ${
                    isLoading ? "animate-spin" : ""
                  }`}
                />
                <span className="text-indigo-700 font-semibold text-sm">
                  {isLoading ? "Refreshing..." : "Refresh"}
                </span>
              </button>
              <div className="flex items-center gap-2.5 bg-gradient-to-r from-emerald-50 to-teal-50 px-5 py-2.5 rounded-full border border-emerald-200/50 shadow-sm">
                <div className="relative">
                  <div className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse"></div>
                  <div className="absolute inset-0 w-2.5 h-2.5 bg-emerald-500 rounded-full animate-ping"></div>
                </div>
                <span className="text-emerald-700 font-semibold text-sm">
                  Live
                </span>
              </div>
              <div className="bg-gray-50 px-5 py-2.5 rounded-full border border-gray-200 shadow-sm">
                <span className="text-gray-700 font-semibold text-sm flex items-center gap-2">
                  <Clock className="w-4 h-4" />
                  {new Date().toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    year: "numeric",
                  })}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Premium Stats Cards - All Clickable */}
        <div className="mb-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <BarChart3 className="w-5 h-5 text-indigo-600" />
              Key Performance Indicators
            </h2>
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <MousePointer2 className="w-4 h-4" />
              <span>Click any card for details</span>
            </div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {statCards.map((stat, index) => (
            <div
              key={index}
              onClick={() => handleKPIClick(stat.type, stat.value)}
              onMouseEnter={() => setHoveredCard(stat.type)}
              onMouseLeave={() => setHoveredCard(null)}
              className={`group relative bg-white rounded-2xl p-6 border transition-all duration-300 hover:scale-[1.02] cursor-pointer overflow-hidden transform-gpu kpi-card ${
                demoMode
                  ? "border-indigo-400 shadow-[0_0_20px_rgba(99,102,241,0.3)] animate-pulse border-2"
                  : "border-gray-100 hover:border-indigo-300 hover:shadow-[0_8px_30px_rgb(99,102,241,0.15)] animate-pulse-subtle"
              }`}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  handleKPIClick(stat.type, stat.value);
                }
              }}
            >
              {/* Animated gradient background on hover */}
              <div
                className={`absolute inset-0 bg-gradient-to-br ${stat.gradient} opacity-0 group-hover:opacity-[0.03] transition-opacity duration-500`}
              ></div>

              {/* Click indicator */}
              <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <div className="bg-white/90 backdrop-blur-sm rounded-full p-1.5 shadow-lg">
                  <ExternalLink className="w-3.5 h-3.5 text-gray-600" />
                </div>
              </div>

              {/* Hover tooltip */}
              {hoveredCard === stat.type && (
                <div className="absolute -top-12 left-1/2 transform -translate-x-1/2 bg-gray-900 text-white px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap z-20 animate-in">
                  Click to view {stat.title.toLowerCase()}
                  <div className="absolute top-full left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-gray-900"></div>
                </div>
              )}

              <div className="relative z-10">
                <div className="flex items-center justify-between mb-5">
                  <div className="relative">
                    <div
                      className={`absolute inset-0 bg-gradient-to-br ${stat.gradient} rounded-xl blur-lg opacity-0 group-hover:opacity-40 transition-opacity duration-300`}
                    ></div>
                    <div
                      className={`relative ${stat.iconBg} p-3.5 rounded-xl shadow-md group-hover:scale-110 group-hover:rotate-3 transition-all duration-300`}
                    >
                      <stat.icon className="w-6 h-6 text-white" />
                    </div>
                  </div>
                  <div
                    className={`flex items-center gap-1.5 ${
                      stat.trend === "up"
                        ? "bg-emerald-50 text-emerald-600 border-emerald-200/50"
                        : "bg-red-50 text-red-600 border-red-200/50"
                    } px-3 py-1.5 rounded-full border`}
                  >
                    {stat.trend === "up" ? (
                      <ArrowUpRight className="w-3.5 h-3.5" />
                    ) : (
                      <ArrowDownRight className="w-3.5 h-3.5" />
                    )}
                    <span className="text-xs font-bold">{stat.change}</span>
                  </div>
                </div>
                <h3 className="text-gray-500 text-xs font-bold mb-2 uppercase tracking-wider">
                  {stat.title}
                </h3>
                <p className="text-3xl font-bold text-gray-900 mb-2">
                  {stat.value}
                </p>
                <p className="text-xs text-gray-500 mb-4">{stat.description}</p>
                <div className="relative h-1 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className={`absolute inset-y-0 left-0 bg-gradient-to-r ${stat.gradient} rounded-full animate-[shimmer_2s_infinite] group-hover:animate-pulse`}
                    style={{ width: "75%" }}
                  ></div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Enhanced Secondary Stats - All Clickable */}
        <div className="mb-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <Target className="w-5 h-5 text-purple-600" />
              System Overview
            </h2>
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <ExternalLink className="w-4 h-4" />
              <span>Interactive dashboard cards</span>
            </div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {secondaryStatCards.map((stat, index) => (
            <div
              key={index}
              onClick={() => handleKPIClick(stat.type, stat.value)}
              className={`bg-white rounded-2xl p-6 border transition-all group cursor-pointer transform-gpu hover:scale-[1.02] ${
                demoMode
                  ? "border-purple-400 shadow-[0_0_20px_rgba(139,92,246,0.3)] animate-pulse border-2"
                  : "border-gray-100 hover:border-purple-300 hover:shadow-[0_8px_30px_rgb(139,92,246,0.15)] animate-pulse-subtle"
              }`}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  handleKPIClick(stat.type, stat.value);
                }
              }}
            >
              {/* Click indicator */}
              <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <div className="bg-white/90 backdrop-blur-sm rounded-full p-1.5 shadow-lg">
                  <MousePointer2 className="w-3 h-3 text-gray-600" />
                </div>
              </div>

              <div className="flex items-center justify-between mb-4">
                <div
                  className={`bg-gradient-to-br ${stat.gradient} p-3 rounded-xl shadow-md group-hover:scale-110 transition-transform`}
                >
                  <stat.icon className="w-6 h-6 text-white" />
                </div>
                <div className="opacity-0 group-hover:opacity-100 transition-opacity">
                  <ExternalLink className="w-4 h-4 text-gray-400" />
                </div>
              </div>
              <p className="text-gray-500 text-xs font-bold uppercase tracking-wider mb-2">
                {stat.title}
              </p>
              <p className="text-3xl font-bold text-gray-900 mb-1">
                {stat.value}
              </p>
              <p className="text-xs text-gray-500 mb-3">{stat.description}</p>
              <div className="flex items-center gap-2 text-xs">
                <span
                  className={`font-semibold ${
                    stat.gradient.includes("blue")
                      ? "text-blue-600"
                      : stat.gradient.includes("purple")
                      ? "text-purple-600"
                      : stat.gradient.includes("emerald")
                      ? "text-emerald-600"
                      : "text-amber-600"
                  }`}
                >
                  {stat.label}
                </span>
                <div className="h-1 flex-1 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className={`h-full bg-gradient-to-r ${stat.gradient} group-hover:animate-pulse`}
                    style={{
                      width:
                        stat.type === "connected_calls"
                          ? `${stats?.conversion_rate || 0}%`
                          : stat.type === "admins"
                          ? "100%"
                          : "75%",
                    }}
                  ></div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Premium Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Call Trends Chart - Larger */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-2.5 rounded-xl shadow-md">
                  <BarChart3 className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">
                    Call Performance Trends
                  </h3>
                  <p className="text-xs text-gray-500">
                    Last 7 days activity overview
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-1.5 bg-indigo-50 px-3 py-1.5 rounded-lg">
                  <div className="w-2 h-2 bg-indigo-500 rounded-full"></div>
                  <span className="text-xs font-semibold text-indigo-700">
                    Total Calls
                  </span>
                </div>
                <div className="flex items-center gap-1.5 bg-emerald-50 px-3 py-1.5 rounded-lg">
                  <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                  <span className="text-xs font-semibold text-emerald-700">
                    Connected
                  </span>
                </div>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={320}>
              <AreaChart data={stats?.call_trends || []}>
                <defs>
                  <linearGradient id="colorCalls" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0.05} />
                  </linearGradient>
                  <linearGradient
                    id="colorConnected"
                    x1="0"
                    y1="0"
                    x2="0"
                    y2="1"
                  >
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0.05} />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="#f3f4f6"
                  vertical={false}
                />
                <XAxis
                  dataKey="date"
                  stroke="#9ca3af"
                  style={{ fontSize: "11px", fontWeight: "600" }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  stroke="#9ca3af"
                  style={{ fontSize: "11px", fontWeight: "600" }}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "12px",
                    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
                    padding: "12px",
                  }}
                  labelStyle={{ fontWeight: "bold", color: "#111827" }}
                />
                <Area
                  type="monotone"
                  dataKey="calls"
                  stroke="#6366f1"
                  fillOpacity={1}
                  fill="url(#colorCalls)"
                  strokeWidth={3}
                  dot={{ fill: "#6366f1", strokeWidth: 2, r: 4 }}
                  activeDot={{ r: 6, strokeWidth: 2 }}
                />
                <Area
                  type="monotone"
                  dataKey="connected"
                  stroke="#10b981"
                  fillOpacity={1}
                  fill="url(#colorConnected)"
                  strokeWidth={3}
                  dot={{ fill: "#10b981", strokeWidth: 2, r: 4 }}
                  activeDot={{ r: 6, strokeWidth: 2 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* Call Distribution Donut */}
          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center gap-3 mb-6">
              <div className="bg-gradient-to-br from-pink-500 to-rose-600 p-2.5 rounded-xl shadow-md">
                <Target className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900">Call Status</h3>
                <p className="text-xs text-gray-500">Distribution breakdown</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={stats?.call_distribution || []}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {(stats?.call_distribution || []).map((_, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index % COLORS.length]}
                      stroke="white"
                      strokeWidth={2}
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "12px",
                    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
                    padding: "12px",
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-4 space-y-2">
              {(stats?.call_distribution || [])
                .slice(0, 4)
                .map((item, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between text-xs"
                  >
                    <div className="flex items-center gap-2">
                      <div
                        className="w-3 h-3 rounded-full"
                        style={{
                          backgroundColor: COLORS[index % COLORS.length],
                        }}
                      ></div>
                      <span className="text-gray-700 font-medium">
                        {item.name}
                      </span>
                    </div>
                    <span className="font-bold text-gray-900">
                      {item.value}
                    </span>
                  </div>
                ))}
            </div>
          </div>
        </div>

        {/* Top Performers & Performance Radar */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Top Performers Bar Chart */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-2.5 rounded-xl shadow-md">
                  <Crown className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">
                    Top Performers
                  </h3>
                  <p className="text-xs text-gray-500">Leaderboard rankings</p>
                </div>
              </div>
              <div className="bg-gradient-to-r from-amber-50 to-orange-50 px-4 py-2 rounded-lg border border-amber-200/50">
                <span className="text-xs font-bold text-amber-700">
                  Today's Best
                </span>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={320}>
              <BarChart data={stats?.top_performers || []} layout="horizontal">
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="#f3f4f6"
                  horizontal={true}
                  vertical={false}
                />
                <XAxis
                  type="number"
                  stroke="#9ca3af"
                  style={{ fontSize: "11px", fontWeight: "600" }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  type="category"
                  dataKey="name"
                  stroke="#9ca3af"
                  style={{ fontSize: "11px", fontWeight: "600" }}
                  tickLine={false}
                  axisLine={false}
                  width={100}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "12px",
                    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
                    padding: "12px",
                  }}
                  cursor={{ fill: "rgba(99, 102, 241, 0.05)" }}
                />
                <Legend />
                <Bar
                  dataKey="calls"
                  fill="#6366f1"
                  radius={[0, 8, 8, 0]}
                  name="Total Calls"
                />
                <Bar
                  dataKey="connected"
                  fill="#10b981"
                  radius={[0, 8, 8, 0]}
                  name="Connected"
                />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Performance Metrics Radar */}
          <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_40px_rgb(0,0,0,0.06)] transition-all">
            <div className="flex items-center gap-3 mb-6">
              <div className="bg-gradient-to-br from-violet-500 to-purple-600 p-2.5 rounded-xl shadow-md">
                <Activity className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900">Performance</h3>
                <p className="text-xs text-gray-500">Key metrics radar</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={280}>
              <RadarChart
                data={[
                  {
                    metric: "Calls",
                    value: Math.min(100, (stats?.total_calls || 0) / 10),
                  },
                  {
                    metric: "Connected",
                    value: Math.min(100, (stats?.connected_calls || 0) / 5),
                  },
                  {
                    metric: "Today",
                    value: Math.min(100, (stats?.calls_today || 0) / 3),
                  },
                  {
                    metric: "Active",
                    value: Math.min(100, ((stats?.active_calls || 0) / 2) * 10),
                  },
                  { metric: "Rate", value: stats?.conversion_rate || 0 },
                ]}
              >
                <PolarGrid stroke="#e5e7eb" />
                <PolarAngleAxis
                  dataKey="metric"
                  style={{
                    fontSize: "11px",
                    fontWeight: "600",
                    fill: "#6b7280",
                  }}
                />
                <PolarRadiusAxis
                  angle={90}
                  domain={[0, 100]}
                  style={{ fontSize: "10px", fill: "#9ca3af" }}
                />
                <Radar
                  name="Performance"
                  dataKey="value"
                  stroke="#8b5cf6"
                  fill="#8b5cf6"
                  fillOpacity={0.6}
                  strokeWidth={2}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "12px",
                    boxShadow: "0 10px 25px rgba(0,0,0,0.1)",
                    padding: "12px",
                  }}
                />
              </RadarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Activity & Quick Stats */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Recent Activity Feed */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="bg-gradient-to-br from-blue-500 to-cyan-600 p-2.5 rounded-xl shadow-md">
                  <Activity className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">
                    Recent Activity
                  </h3>
                  <p className="text-xs text-gray-500">Live call updates</p>
                </div>
              </div>
              <div className="flex items-center gap-2 bg-blue-50 px-3 py-1.5 rounded-lg">
                <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                <span className="text-xs font-semibold text-blue-700">
                  Live
                </span>
              </div>
            </div>
            <div className="space-y-2 max-h-[400px] overflow-y-auto custom-scrollbar">
              {(stats?.recent_activity || []).map((activity, index) => {
                const isConnected = activity.action.includes("Connected");
                const isMissed =
                  activity.action.includes("Missed") ||
                  activity.action.includes("not_answered");
                const isPending =
                  activity.action.includes("Pending") ||
                  activity.action.includes("pending");

                return (
                  <div
                    key={index}
                    className="bg-gray-50 rounded-xl p-4 border border-gray-100 hover:bg-white hover:shadow-md hover:border-gray-200 transition-all group"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3 flex-1">
                        <div
                          className={`w-10 h-10 rounded-xl flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform ${
                            isConnected
                              ? "bg-gradient-to-br from-emerald-500 to-teal-600"
                              : isMissed
                              ? "bg-gradient-to-br from-red-500 to-rose-600"
                              : isPending
                              ? "bg-gradient-to-br from-amber-500 to-orange-600"
                              : "bg-gradient-to-br from-indigo-500 to-purple-600"
                          }`}
                        >
                          {isConnected ? (
                            <CheckCircle2 className="w-5 h-5 text-white" />
                          ) : isMissed ? (
                            <XCircle className="w-5 h-5 text-white" />
                          ) : isPending ? (
                            <Timer className="w-5 h-5 text-white" />
                          ) : (
                            <PhoneIncoming className="w-5 h-5 text-white" />
                          )}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-bold text-gray-900 text-sm truncate">
                            {activity.telecaller}
                          </p>
                          <p className="text-xs text-gray-600 truncate">
                            {activity.action}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 ml-3">
                        <span className="text-xs text-gray-500 bg-white px-3 py-1.5 rounded-lg font-medium border border-gray-200 whitespace-nowrap">
                          {activity.time}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Quick Stats Summary */}
          <div className="space-y-4">
            {/* Call Success Rate */}
            <div className="bg-gradient-to-br from-emerald-500 to-teal-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all">
              <div className="flex items-center justify-between mb-4">
                <div className="bg-white/20 backdrop-blur-xl p-2.5 rounded-xl">
                  <Target className="w-6 h-6 text-white" />
                </div>
                <TrendingUp className="w-5 h-5 text-white/70" />
              </div>
              <p className="text-white/80 text-xs font-bold uppercase tracking-wider mb-2">
                Success Rate
              </p>
              <p className="text-4xl font-bold mb-3">
                {stats?.conversion_rate || 0}%
              </p>
              <div className="bg-white/20 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-white h-full rounded-full transition-all duration-1000"
                  style={{ width: `${stats?.conversion_rate || 0}%` }}
                ></div>
              </div>
            </div>

            {/* Total Calls Summary */}
            <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-2.5 rounded-xl">
                  <Phone className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-bold uppercase tracking-wider">
                    Total Calls
                  </p>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats?.total_calls || 0}
                  </p>
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                    Connected
                  </span>
                  <span className="font-bold text-gray-900">
                    {stats?.connected_calls || 0}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <Timer className="w-3.5 h-3.5 text-amber-500" />
                    Active
                  </span>
                  <span className="font-bold text-gray-900">
                    {stats?.active_calls || 0}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-600 flex items-center gap-2">
                    <Calendar className="w-3.5 h-3.5 text-blue-500" />
                    Today
                  </span>
                  <span className="font-bold text-gray-900">
                    {stats?.calls_today || 0}
                  </span>
                </div>
              </div>
            </div>

            {/* Team Summary */}
            <div className="bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all">
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-white/20 backdrop-blur-xl p-2.5 rounded-xl">
                  <Users className="w-6 h-6 text-white" />
                </div>
                <div>
                  <p className="text-white/80 text-xs font-bold uppercase tracking-wider">
                    Team Size
                  </p>
                  <p className="text-2xl font-bold">
                    {(stats?.total_telecallers || 0) +
                      (stats?.total_managers || 0)}
                  </p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-white/10 backdrop-blur-xl rounded-lg p-3">
                  <p className="text-white/70 text-xs mb-1">Telecallers</p>
                  <p className="text-xl font-bold">
                    {stats?.total_telecallers || 0}
                  </p>
                </div>
                <div className="bg-white/10 backdrop-blur-xl rounded-lg p-3">
                  <p className="text-white/70 text-xs mb-1">Managers</p>
                  <p className="text-xl font-bold">
                    {stats?.total_managers || 0}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* System Status Footer */}
        <div className="bg-white rounded-2xl p-6 border border-gray-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">
                    System Status
                  </p>
                  <p className="text-sm font-bold text-gray-900">
                    All Systems Operational
                  </p>
                </div>
              </div>
              <div className="h-8 w-px bg-gray-200"></div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-xl flex items-center justify-center">
                  <Activity className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">
                    Database
                  </p>
                  <p className="text-sm font-bold text-gray-900">Connected</p>
                </div>
              </div>
              <div className="h-8 w-px bg-gray-200"></div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center">
                  <Zap className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-500 font-semibold">
                    API Response
                  </p>
                  <p className="text-sm font-bold text-gray-900">Fast</p>
                </div>
              </div>
            </div>
            <div className="text-xs text-gray-500">
              Last updated:{" "}
              <span className="font-semibold text-gray-700">
                {new Date().toLocaleTimeString()}
              </span>
            </div>
          </div>
        </div>

        {/* Interactive Help Text */}
        <div className="mt-6 bg-gradient-to-r from-indigo-50 to-purple-50 rounded-2xl p-6 border border-indigo-100">
          <div className="text-center">
            <div className="flex items-center justify-center gap-3 mb-3">
              <div className="bg-indigo-100 p-2 rounded-full">
                <MousePointer2 className="w-5 h-5 text-indigo-600" />
              </div>
              <h3 className="text-lg font-bold text-gray-900">
                Interactive Dashboard
              </h3>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              All {statCards.length + secondaryStatCards.length} KPI cards are
              clickable and will navigate you to detailed views
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
              <div className="flex items-center gap-2 text-indigo-600">
                <div className="w-2 h-2 bg-indigo-500 rounded-full animate-pulse"></div>
                <span>Telecallers → Team Management</span>
              </div>
              <div className="flex items-center gap-2 text-emerald-600">
                <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></div>
                <span>Calls → Call Center</span>
              </div>
              <div className="flex items-center gap-2 text-blue-600">
                <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                <span>Analytics → Reports</span>
              </div>
              <div className="flex items-center gap-2 text-purple-600">
                <div className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></div>
                <span>System → Administration</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Notification Toast */}
      {notification && (
        <div className="fixed top-4 right-4 z-50 animate-in slide-in-from-right duration-300">
          <div
            className={`rounded-xl p-4 shadow-lg border backdrop-blur-sm ${
              notification.type === "info"
                ? "bg-blue-50/90 border-blue-200 text-blue-800"
                : "bg-amber-50/90 border-amber-200 text-amber-800"
            }`}
          >
            <div className="flex items-center gap-3">
              <div
                className={`p-1.5 rounded-lg ${
                  notification.type === "info" ? "bg-blue-100" : "bg-amber-100"
                }`}
              >
                {notification.type === "info" ? (
                  <ExternalLink className="w-4 h-4" />
                ) : (
                  <AlertCircle className="w-4 h-4" />
                )}
              </div>
              <div>
                <p className="font-semibold text-sm">{notification.message}</p>
                <p className="text-xs opacity-75">
                  Value: {notification.value}
                </p>
              </div>
              <button
                onClick={() => setNotification(null)}
                className="ml-2 p-1 hover:bg-black/10 rounded-lg transition-colors"
              >
                <XCircle className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
