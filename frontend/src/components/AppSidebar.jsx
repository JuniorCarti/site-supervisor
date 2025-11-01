import { NavLink, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Wrench, 
  FolderKanban, 
  Users, 
  DollarSign, 
  Brain, 
  BarChart3,
  Settings
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from './ui/sidebar';

const AppSidebar = () => {
  const { user } = useAuth();
  const { state } = useSidebar();
  const location = useLocation();

  const navigation = [
    {
      title: 'Main',
      items: [
        { title: 'Dashboard', url: `/${user?.role?.toLowerCase()}/dashboard`, icon: LayoutDashboard, roles: ['Admin', 'Manager', 'Driver'] },
        { title: 'Analytics', url: '/analytics', icon: BarChart3, roles: ['Admin', 'Manager'] },
      ],
    },
    {
      title: 'Operations',
      items: [
        { title: 'Maintenance', url: '/maintenance', icon: Wrench, roles: ['Admin', 'Manager', 'Driver'] },
        { title: 'Projects', url: '/projects', icon: FolderKanban, roles: ['Admin', 'Manager', 'Driver'] },
        { title: 'Suppliers', url: '/suppliers', icon: Users, roles: ['Admin', 'Manager', 'Driver'] },
        { title: 'Finance', url: '/finance', icon: DollarSign, roles: ['Admin', 'Manager', 'Driver'] },
      ],
    },
    {
      title: 'AI Agents',
      items: [
        { title: 'AI Console', url: '/ai', icon: Brain, roles: ['Admin', 'Manager', 'Driver'] },
      ],
    },
  ];

  const isActive = (path) => location.pathname === path;

  const filterByRole = (items) => {
    return items.filter(item => item.roles.includes(user?.role));
  };

  return (
    <Sidebar collapsible="icon">
      <SidebarContent>
        {navigation.map((section) => {
          const filteredItems = filterByRole(section.items);
          if (filteredItems.length === 0) return null;

          return (
            <SidebarGroup key={section.title}>
              <SidebarGroupLabel>{section.title}</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {filteredItems.map((item) => (
                    <SidebarMenuItem key={item.title}>
                      <SidebarMenuButton asChild isActive={isActive(item.url)}>
                        <NavLink to={item.url}>
                          <item.icon className="h-4 w-4" />
                          <span>{item.title}</span>
                        </NavLink>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          );
        })}
      </SidebarContent>
    </Sidebar>
  );
};

export default AppSidebar;
