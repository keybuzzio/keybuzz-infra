#!/usr/bin/env python3
"""
PH28.23B: Create profile API route and update settings page
"""
import os

# Create the profile API route
profile_route_content = '''// app/api/tenant-context/profile/[tenantId]/route.ts
// PH28.23B: Proxy to backend for tenant profile GET/PUT

import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../../auth/[...nextauth]/auth-options';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io';
export const dynamic = 'force-dynamic';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ tenantId: string }> }
) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const userEmail = session.user.email;
    const { tenantId } = await params;

    const response = await fetch(`${API_URL}/tenant-context/profile/${tenantId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': userEmail,
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Profile GET] Backend error:', response.status, errorText.substring(0, 200));
      return NextResponse.json(
        { error: 'Failed to get profile', details: errorText.substring(0, 200) },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);

  } catch (error) {
    console.error('[Profile GET] Error:', error);
    return NextResponse.json(
      { error: 'Internal error', details: (error as Error).message },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ tenantId: string }> }
) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const userEmail = session.user.email;
    const { tenantId } = await params;
    const body = await request.json();

    const response = await fetch(`${API_URL}/tenant-context/profile/${tenantId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': userEmail,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Profile PUT] Backend error:', response.status, errorText.substring(0, 200));
      return NextResponse.json(
        { error: 'Failed to update profile', details: errorText.substring(0, 200) },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);

  } catch (error) {
    console.error('[Profile PUT] Error:', error);
    return NextResponse.json(
      { error: 'Internal error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
'''

# Write the profile route
route_dir = '/opt/keybuzz/keybuzz-client/app/api/tenant-context/profile/[tenantId]'
os.makedirs(route_dir, exist_ok=True)
route_path = f'{route_dir}/route.ts'
with open(route_path, 'w') as f:
    f.write(profile_route_content)
print(f'Created {route_path}')

# Now modify the settings page
settings_path = '/opt/keybuzz/keybuzz-client/app/settings/page.tsx'
with open(settings_path, 'r') as f:
    content = f.read()

# 1. Add profileLoading state after existing states
old_focus_state = '''const [focusMode, setFocusMode] = useState(true);
  const [tenantId, setTenantId] = useState<string | null>(null);'''

new_focus_state = '''const [focusMode, setFocusMode] = useState(true);
  const [tenantId, setTenantId] = useState<string | null>(null);
  const [profileLoading, setProfileLoading] = useState(true);
  const [profileError, setProfileError] = useState<string | null>(null);'''

if old_focus_state in content:
    content = content.replace(old_focus_state, new_focus_state)
    print('Added profileLoading and profileError states')
else:
    print('WARNING: Could not find focus state to add profile states')

# 2. Find the existing useEffect that loads from localStorage and modify it
# We need to add a new useEffect that fetches from API using currentTenantId from useTenant

# Find the useEffect and add profile fetching after it
old_useeffect_end = '''} catch (e) {
      console.warn("Failed to load settings:", e);
    }
  }, []);'''

new_useeffect_with_profile = '''} catch (e) {
      console.warn("Failed to load settings:", e);
    }
  }, []);

  // PH28.23B: Fetch profile from API when tenant changes
  useEffect(() => {
    if (!currentTenantId) {
      setProfileLoading(false);
      return;
    }
    
    const fetchProfile = async () => {
      setProfileLoading(true);
      setProfileError(null);
      try {
        const res = await fetch(`/api/tenant-context/profile/${currentTenantId}`, {
          credentials: 'include',
        });
        
        if (res.ok) {
          const data = await res.json();
          // Update profile with API data
          if (data.profile) {
            setProfile({
              companyName: data.profile.companyName || data.tenant?.name || '',
              email: data.profile.supportEmail || '',
              phone: profile.phone, // Keep local value for now
              returnAddress: profile.returnAddress, // Keep local value for now
            });
          } else if (data.tenant?.name) {
            // No profile yet, use tenant name
            setProfile(prev => ({
              ...prev,
              companyName: data.tenant.name,
              email: data.profile?.supportEmail || prev.email,
            }));
          }
        } else if (res.status !== 404) {
          console.error('[Settings] Failed to fetch profile:', res.status);
          setProfileError('Impossible de charger le profil');
        }
      } catch (err) {
        console.error('[Settings] Profile fetch error:', err);
        setProfileError('Erreur de connexion');
      } finally {
        setProfileLoading(false);
      }
    };
    
    fetchProfile();
  }, [currentTenantId]);'''

if old_useeffect_end in content:
    content = content.replace(old_useeffect_end, new_useeffect_with_profile)
    print('Added profile fetch useEffect')
else:
    print('WARNING: Could not find useEffect end to add profile fetch')

# 3. Modify saveSettings to also call the API
old_save_settings = '''const saveSettings = useCallback(() => {
    if (typeof window === "undefined") return;
    try {
      const data = { profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      
      if (tenantId) {
        setFocusModeStorage(tenantId, focusMode);
      }
      
      setToast("Parametres enregistres");
      setTimeout(() => setToast(null), 3000);
    } catch (e) {
      console.error("Failed to save settings:", e);
    }
  }, [profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled, focusMode, tenantId]);'''

new_save_settings = '''const saveSettings = useCallback(async () => {
    if (typeof window === "undefined") return;
    try {
      // Save to localStorage for other settings
      const data = { profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      
      if (tenantId) {
        setFocusModeStorage(tenantId, focusMode);
      }
      
      // PH28.23B: Save profile to API
      const effectiveTenantId = currentTenantId || tenantId;
      if (effectiveTenantId) {
        try {
          const res = await fetch(`/api/tenant-context/profile/${effectiveTenantId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({
              companyName: profile.companyName,
              supportEmail: profile.email,
            }),
          });
          
          if (!res.ok) {
            console.error('[Settings] Failed to save profile to API:', res.status);
          }
        } catch (apiErr) {
          console.error('[Settings] API save error:', apiErr);
        }
      }
      
      setToast("Parametres enregistres");
      setTimeout(() => setToast(null), 3000);
    } catch (e) {
      console.error("Failed to save settings:", e);
    }
  }, [profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled, focusMode, tenantId, currentTenantId]);'''

if old_save_settings in content:
    content = content.replace(old_save_settings, new_save_settings)
    print('Modified saveSettings to use API')
else:
    print('WARNING: Could not find saveSettings to modify')

# 4. Update the default profile to show empty instead of fake data
old_default = '''const defaultProfile: BusinessProfile = {
  companyName: "Ma Boutique",
  email: "support@maboutique.com",
  phone: "+33 1 23 45 67 89",
  returnAddress: "12 Rue du Commerce\\n75001 Paris\\nFrance"
};'''

new_default = '''const defaultProfile: BusinessProfile = {
  companyName: "",
  email: "",
  phone: "",
  returnAddress: ""
};'''

if old_default in content:
    content = content.replace(old_default, new_default)
    print('Updated default profile to empty values')
else:
    print('WARNING: Could not find default profile to update')

# Write the modified content
with open(settings_path, 'w') as f:
    f.write(content)
print(f'Updated {settings_path}')

print('\\nDone! Profile API integration added.')
