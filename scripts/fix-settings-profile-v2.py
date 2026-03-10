#!/usr/bin/env python3
"""
PH28.23B v2: Fix the settings page - move useEffect after useTenant()
"""

settings_path = '/opt/keybuzz/keybuzz-client/app/settings/page.tsx'
with open(settings_path, 'r') as f:
    content = f.read()

# The problem is that the profile fetch useEffect references currentTenantId
# but currentTenantId comes from useTenant() which is declared later.
# Solution: Remove the useEffect we added and put it in a better place.

# First, remove the wrongly placed useEffect
wrong_useeffect = '''
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

if wrong_useeffect in content:
    content = content.replace(wrong_useeffect, '')
    print('Removed wrongly placed useEffect')
else:
    print('WARNING: Could not find wrongly placed useEffect')

# Now find a good place AFTER useTenant() is called
# The useTenant() call is:
# const { tenants, currentTenantId, setCurrentTenant, refreshTenants, isLoading: tenantsLoading } = useTenant();

# Find after the formData state which is after useTenant
insert_after = '''const [formData, setFormData] = useState({ name: '', country: 'FR' });'''

profile_fetch_useeffect = '''const [formData, setFormData] = useState({ name: '', country: 'FR' });

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

if insert_after in content:
    content = content.replace(insert_after, profile_fetch_useeffect)
    print('Added profile fetch useEffect after useTenant()')
else:
    print('WARNING: Could not find insertion point after formData')

with open(settings_path, 'w') as f:
    f.write(content)
print(f'Updated {settings_path}')

print('\\nDone! Profile useEffect repositioned.')
