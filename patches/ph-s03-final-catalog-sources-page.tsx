/**
 * PH-S02.1: Page Sources de Produits
 * Wizard avec flux FTP integre
 * PH-S03.4: Wizard sans matching ; onglet "Colonnes (CSV)" en fiche source
 */

'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/src/hooks/useAuth';
import { api, getDisplayErrorMessage } from '@/src/lib/api';
import { buildFieldsPayload } from '@/src/lib/catalogSourceFields';
import FtpConnection from './FtpConnection';
import { 
  Package, 
  Plus,
  Trash2,
  Loader2,
  AlertCircle,
  ShoppingCart,
  Store,
  Puzzle,
  FileText,
  Globe,
  Settings,
  ChevronRight,
  ChevronLeft,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  CircleDot,
  ArrowUpDown,
  Edit,
  Eye,
  X,
  Plug,
  File,
  Folder,
  Server,
  Lock,
  User,
  Hash,
  RefreshCw
} from 'lucide-react';

// ============================================
// TYPES
// ============================================

type SourceKind = 'supplier' | 'ecommerce_platform' | 'marketplace' | 'erp';
type SourceTypeExtended = 'ftp_csv' | 'ftp_xml' | 'http_file' | 'api_generic' | 'shopify' | 'prestashop' | 'woocommerce' | 'marketplace_reference';
type SourceStatus = 'ready' | 'to_complete' | 'error' | 'disabled';
type ConnectionStatus = 'not_configured' | 'connected' | 'error';
type FileType = 'file' | 'directory';

interface SourceField {
  id: string;
  tenant_id: string;
  source_id: string;
  field_code: string;
  field_label: string;
  required: boolean;
  created_at: string;
  updated_at: string;
}

interface CatalogSource {
  id: string;
  tenantId: string;
  name: string;
  source_kind: SourceKind;
  source_type_ext: SourceTypeExtended;
  priority: number;
  status: SourceStatus;
  human_label: string | null;
  description: string | null;
  isActive: boolean;
  fields_count: number;
  fields?: SourceField[];
  createdAt: string;
  updatedAt: string;
  connection_type: string | null;
  connection_status: ConnectionStatus;
  last_connection_check_at: string | null;
  last_connection_error: string | null;
  selected_files_count: number;
}

interface FtpFileItem {
  name: string;
  path: string;
  type: FileType;
  size: number | null;
  modified: string | null;
}

interface FieldCodeOption {
  code: string;
  label: string;
  description: string;
  default_required: boolean;
}

// PH-S02.2: Types pour le mapping de colonnes
interface DetectedHeader {
  index: number;
  name: string;
  sample_values: string[];
}

interface ColumnMapping {
  sourceColumn: string;
  sourceColumnIndex: number;
  targetField: string;
  targetFieldLabel: string;
}

interface ProductFieldOption {
  field: string;
  label: string;
  required: boolean;
}

// ============================================
// CONSTANTES UI
// ============================================

const SOURCE_KIND_CONFIG = {
  supplier: {
    icon: Package,
    label: 'Fournisseur',
    description: 'Vos fournisseurs vous envoient des fichiers produits',
    color: 'text-blue-400',
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/30',
  },
  ecommerce_platform: {
    icon: ShoppingCart,
    label: 'Boutique en ligne',
    description: 'Votre boutique Shopify, PrestaShop, WooCommerce...',
    color: 'text-green-400',
    bg: 'bg-green-500/10',
    border: 'border-green-500/30',
  },
  marketplace: {
    icon: Store,
    label: 'Marketplace',
    description: 'Amazon, Cdiscount, Fnac...',
    color: 'text-purple-400',
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/30',
  },
  erp: {
    icon: Puzzle,
    label: 'Autre systeme',
    description: 'ERP, PIM, ou autre systeme interne',
    color: 'text-orange-400',
    bg: 'bg-orange-500/10',
    border: 'border-orange-500/30',
  },
};

const SOURCE_TYPE_CONFIG: Record<SourceTypeExtended, { 
  icon: typeof FileText; 
  label: string; 
  description: string;
  forKinds: SourceKind[];
  needsFtp: boolean;
}> = {
  ftp_csv: {
    icon: FileText,
    label: 'Fichier CSV',
    description: 'Fichier CSV sur un serveur FTP',
    forKinds: ['supplier', 'erp'],
    needsFtp: true,
  },
  ftp_xml: {
    icon: FileText,
    label: 'Fichier XML',
    description: 'Fichier XML sur un serveur FTP',
    forKinds: ['supplier', 'erp'],
    needsFtp: true,
  },
  http_file: {
    icon: Globe,
    label: 'Fichier HTTP',
    description: 'Fichier accessible par URL',
    forKinds: ['supplier', 'erp'],
    needsFtp: true,
  },
  api_generic: {
    icon: Settings,
    label: 'API personnalisee',
    description: 'API REST ou SOAP',
    forKinds: ['supplier', 'erp'],
    needsFtp: false,
  },
  shopify: {
    icon: ShoppingCart,
    label: 'Shopify',
    description: 'Connexion a votre boutique Shopify',
    forKinds: ['ecommerce_platform'],
    needsFtp: false,
  },
  prestashop: {
    icon: ShoppingCart,
    label: 'PrestaShop',
    description: 'Connexion a votre boutique PrestaShop',
    forKinds: ['ecommerce_platform'],
    needsFtp: false,
  },
  woocommerce: {
    icon: ShoppingCart,
    label: 'WooCommerce',
    description: 'Connexion a votre boutique WooCommerce',
    forKinds: ['ecommerce_platform'],
    needsFtp: false,
  },
  marketplace_reference: {
    icon: Store,
    label: 'Reference Marketplace',
    description: 'Catalogue de reference marketplace',
    forKinds: ['marketplace'],
    needsFtp: false,
  },
};

const STATUS_CONFIG = {
  ready: {
    icon: CheckCircle2,
    label: 'Prete',
    color: 'text-green-400',
    bg: 'bg-green-500/10',
    border: 'border-green-500/30',
  },
  to_complete: {
    icon: AlertTriangle,
    label: 'A completer',
    color: 'text-yellow-400',
    bg: 'bg-yellow-500/10',
    border: 'border-yellow-500/30',
  },
  error: {
    icon: XCircle,
    label: 'Erreur',
    color: 'text-red-400',
    bg: 'bg-red-500/10',
    border: 'border-red-500/30',
  },
  disabled: {
    icon: CircleDot,
    label: 'Desactivee',
    color: 'text-slate-400',
    bg: 'bg-slate-500/10',
    border: 'border-slate-500/30',
  },
};

const FIELD_CODE_OPTIONS: FieldCodeOption[] = [
  { code: 'sku', label: 'Reference produit (SKU)', description: 'Identifiant unique du produit', default_required: true },
  { code: 'stock', label: 'Quantite disponible', description: 'Stock disponible', default_required: false },
  { code: 'ean', label: 'Code-barres (EAN)', description: 'Code EAN/UPC', default_required: false },
  { code: 'price_buy', label: 'Prix d\'achat', description: 'Prix d\'achat HT', default_required: false },
  { code: 'price_sell', label: 'Prix de vente conseille', description: 'Prix de vente TTC', default_required: false },
  { code: 'brand', label: 'Marque', description: 'Marque du produit', default_required: false },
  { code: 'product_name', label: 'Nom du produit', description: 'Designation du produit', default_required: false },
];

// ============================================
// COMPOSANT PRINCIPAL
// ============================================

export default function CatalogSourcesPage() {
  const { tenantId, isLoading: authLoading } = useAuth();
  const [sources, setSources] = useState<CatalogSource[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Wizard state
  const [showWizard, setShowWizard] = useState(false);
  const [wizardStep, setWizardStep] = useState(1);
  const [wizardData, setWizardData] = useState<{
    kind: SourceKind | null;
    type: SourceTypeExtended | null;
    // FTP config
    ftpProtocol: 'ftp' | 'sftp';
    ftpHost: string;
    ftpPort: number;
    ftpUsername: string;
    ftpPassword: string;
    ftpConnected: boolean;
    secretRefId: string; // PH-S03.2: optionnel, pour connexion durable
    // File selection
    selectedFiles: { path: string; filename: string }[];
    // PH-S02.2: Column mapping
    detectedHeaders: DetectedHeader[];
    columnMappings: ColumnMapping[];
    // Final info
    name: string;
    description: string;
    priority: number;
    fields: { code: string; label: string; required: boolean }[];
  }>({
    kind: null,
    type: null,
    ftpProtocol: 'ftp',
    ftpHost: '',
    ftpPort: 21,
    ftpUsername: '',
    ftpPassword: '',
    ftpConnected: false,
    secretRefId: '',
    selectedFiles: [],
    detectedHeaders: [],
    columnMappings: [],
    name: '',
    description: '',
    priority: 100,
    fields: [],
  });
  
  // Detail view
  const [selectedSource, setSelectedSource] = useState<CatalogSource | null>(null);
  const [showDetail, setShowDetail] = useState(false);

  // ============================================
  // DATA LOADING
  // ============================================

  const loadSources = useCallback(async () => {
    if (!tenantId) return;

    const endpoint = '/api/catalog-sources?include_fields=true';
    try {
      setIsLoading(true);
      setError(null);
      const data = await api.get<CatalogSource[]>(endpoint);
      setSources(data);
    } catch (err) {
      const status = (err as Error & { status?: number }).status;
      const errEndpoint = (err as Error & { endpoint?: string }).endpoint ?? endpoint;
      const message = err instanceof Error ? err.message : String(err);
      if (typeof window !== 'undefined') {
        console.warn('[CatalogSources] load failed', { endpoint: errEndpoint, status, message });
      }
      // PH-S03.5B: erreurs non bloquantes = pas de bandeau global, liste vide
      if (status === 400 && /tenant|X-Tenant-Id/i.test(message)) {
        setSources([]);
        return;
      }
      if (status === 404 && /tenant|source|not found|introuvable/i.test(message)) {
        setSources([]);
        return;
      }
      setError(getDisplayErrorMessage(err));
    } finally {
      setIsLoading(false);
    }
  }, [tenantId]);

  useEffect(() => {
    if (tenantId && !authLoading) {
      loadSources();
    }
  }, [tenantId, authLoading, loadSources]);

  // ============================================
  // ACTIONS
  // ============================================

  // State pour l'erreur de creation dans le wizard
  const [createError, setCreateError] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);

  async function createSource() {
    if (!wizardData.kind || !wizardData.type || !wizardData.name) return;
    
    setCreateError(null);
    setIsCreating(true);
    let source: CatalogSource | null = null;
    
    try {
      // PH-S03.4: Wizard ne fait plus le mapping — status = to_complete (mapping dans onglet "Colonnes (CSV)")
      const needsFtpForReady = SOURCE_TYPE_CONFIG[wizardData.type!]?.needsFtp;
      const hasDurableFtp = !needsFtpForReady || !!wizardData.secretRefId;
      const hasFiles = wizardData.selectedFiles.length > 0;
      const isReady = hasFiles && hasDurableFtp; // SKU mapping fait après création dans fiche source

      // 1. Creer la source
      source = await api.post<CatalogSource>('/api/catalog-sources', {
        name: wizardData.name,
        source_kind: wizardData.kind,
        source_type_ext: wizardData.type,
        priority: wizardData.priority,
        description: wizardData.description || null,
        status: isReady ? 'ready' : 'to_complete',
      });
      loadSources();

      // 2. Configurer les champs (PH-S03.1 B) payload verrouillé field_code/field_label/required)
      if (wizardData.fields.length > 0) {
        await api.put(
          `/api/catalog-sources/${source.id}/fields`,
          buildFieldsPayload(wizardData.fields)
        );
      }
      
      // 3. PH-S03.2: Configurer FTP PERSISTANT uniquement si secret_ref_id (jamais de password en DB)
      const needsFtp = SOURCE_TYPE_CONFIG[wizardData.type]?.needsFtp;
      if (needsFtp && wizardData.ftpHost && wizardData.secretRefId) {
        await api.post(`/api/catalog-sources/${source.id}/ftp/connection`, {
          protocol: wizardData.ftpProtocol,
          host: wizardData.ftpHost,
          port: wizardData.ftpPort,
          username: wizardData.ftpUsername || null,
          secret_ref_id: wizardData.secretRefId,
        });
        for (const file of wizardData.selectedFiles) {
          await api.post(`/api/catalog-sources/${source.id}/ftp/select-file`, {
            remote_path: file.path,
            selected: true,
          });
        }
      }
      // PH-S03.4: Plus d'appel column-mappings/bulk dans le wizard — mapping dans onglet "Colonnes (CSV)" après création
      
      closeWizard();
      loadSources();
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erreur de creation';
      const isNetworkError =
        errorMessage.includes('Failed to fetch') ||
        errorMessage.includes('Impossible de joindre le serveur') ||
        errorMessage.includes('connexion');
      if (isNetworkError) {
        loadSources();
      }
      // PH-S03.1 C) "Nom déjà existant" uniquement si POST create a échoué avec 409 (conflit de nom)
      const isCreateConflict =
        !source &&
        (errorMessage.includes('catalog source') && errorMessage.toLowerCase().includes('already exists') ||
          errorMessage.includes('existe deja') ||
          errorMessage.includes('Conflict'));
      if (isCreateConflict) {
        setCreateError(
          `Une source avec le nom "${wizardData.name}" existe déjà. Veuillez choisir un autre nom.`
        );
      } else if (source) {
        // PH-S03.1 C) Source créée mais étape post-création échouée : message + ouverture fiche source
        const incompleteMessage =
          'Source créée, configuration incomplète. Complétez la configuration (FTP, mapping) depuis la fiche source.';
        closeWizard();
        loadSources();
        setSelectedSource(source);
        setShowDetail(true);
        setError(incompleteMessage);
      } else {
        setCreateError(
          isNetworkError
            ? 'La connexion a été interrompue. Vérifiez la liste ci-dessous : la source a peut-être été créée.'
            : errorMessage
        );
      }
    } finally {
      setIsCreating(false);
    }
  }

  async function deleteSource(id: string) {
    if (!confirm('Supprimer cette source ?')) return;
    
    try {
      await api.delete(`/api/catalog-sources/${id}`);
      loadSources();
      if (selectedSource?.id === id) {
        setShowDetail(false);
        setSelectedSource(null);
      }
    } catch (err) {
      setError(getDisplayErrorMessage(err));
    }
  }

  async function updateSourceStatus(id: string, status: SourceStatus) {
    try {
      await api.patch(`/api/catalog-sources/${id}/status?status=${status}`, {});
      loadSources();
      if (selectedSource?.id === id) {
        setSelectedSource({ ...selectedSource, status });
      }
    } catch (err) {
      setError(getDisplayErrorMessage(err));
    }
  }

  function openSourceDetail(source: CatalogSource) {
    setSelectedSource(source);
    setShowDetail(true);
  }

  function closeWizard() {
    setShowWizard(false);
    setWizardStep(1);
    setCreateError(null);
    setIsCreating(false);
    setWizardData({
      kind: null,
      type: null,
      ftpProtocol: 'ftp',
      ftpHost: '',
      ftpPort: 21,
      ftpUsername: '',
      ftpPassword: '',
      ftpConnected: false,
      secretRefId: '',
      selectedFiles: [],
      detectedHeaders: [],
      columnMappings: [],
      name: '',
      description: '',
      priority: 100,
      fields: [],
    });
  }

  // ============================================
  // RENDER
  // ============================================

  if (authLoading || isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 animate-spin text-primary-500" />
      </div>
    );
  }

  // PH-S03.4: Wizard sans matching — matching = onglet "Colonnes (CSV)" après création
  // needsFtp: 1=kind, 2=type, 3=ftp, 4=files, 5=finalize
  // !needsFtp: 1=kind, 2=type, 3=finalize
  const needsFtp = wizardData.type ? SOURCE_TYPE_CONFIG[wizardData.type]?.needsFtp : false;
  const totalSteps = needsFtp ? 5 : 3;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-3">
            <Package className="h-7 w-7 text-primary-400" />
            Sources de produits
          </h1>
          <p className="text-slate-400 mt-1">
            Declarez d&apos;ou viennent vos produits et structurez les informations attendues
          </p>
        </div>
        <button
          onClick={() => setShowWizard(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
        >
          <Plus className="h-5 w-5" />
          Ajouter une source
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0" />
          <p className="text-red-400 flex-1">{error}</p>
          <button onClick={() => setError(null)} className="text-red-400 hover:text-red-300">
            <X className="h-5 w-5" />
          </button>
        </div>
      )}

      {/* Empty state */}
      {sources.length === 0 && !error && (
        <div className="bg-slate-800/50 backdrop-blur-sm border border-slate-700 rounded-xl p-12 text-center">
          <Package className="h-16 w-16 text-slate-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-white mb-2">
            Aucune source configuree
          </h2>
          <p className="text-slate-400 mb-6 max-w-md mx-auto">
            Declarez vos sources de produits : fournisseurs, boutique en ligne, marketplace ou autre systeme.
          </p>
          <button
            onClick={() => setShowWizard(true)}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
          >
            <Plus className="h-5 w-5" />
            Ajouter ma premiere source
          </button>
        </div>
      )}

      {/* Sources list */}
      {sources.length > 0 && (
        <div className="grid gap-4">
          {sources.map((source) => {
            const kindConfig = SOURCE_KIND_CONFIG[source.source_kind] || SOURCE_KIND_CONFIG.supplier;
            const statusConfig = STATUS_CONFIG[source.status] || STATUS_CONFIG.to_complete;
            const KindIcon = kindConfig.icon;
            const StatusIcon = statusConfig.icon;
            
            return (
              <div
                key={source.id}
                className="bg-slate-800/50 backdrop-blur-sm border border-slate-700 rounded-xl p-5 hover:border-slate-600 transition-colors"
              >
                <div className="flex items-center gap-4">
                  {/* Icon */}
                  <div className={`p-3 rounded-xl ${kindConfig.bg} ${kindConfig.border} border`}>
                    <KindIcon className={`h-6 w-6 ${kindConfig.color}`} />
                  </div>
                  
                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3">
                      <h3 className="text-lg font-semibold text-white truncate">
                        {source.name}
                      </h3>
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${statusConfig.bg} ${statusConfig.color} ${statusConfig.border} border`}>
                        <StatusIcon className="h-3.5 w-3.5" />
                        {statusConfig.label}
                      </span>
                    </div>
                    <div className="flex items-center gap-4 mt-1.5 text-sm text-slate-400 flex-wrap">
                      <span>{kindConfig.label}</span>
                      <span className="text-slate-600">•</span>
                      <span>{SOURCE_TYPE_CONFIG[source.source_type_ext]?.label || source.source_type_ext}</span>
                      <span className="text-slate-600">•</span>
                      <span className="flex items-center gap-1">
                        <ArrowUpDown className="h-3.5 w-3.5" />
                        Priorite {source.priority}
                      </span>
                      {source.fields_count > 0 && (
                        <>
                          <span className="text-slate-600">•</span>
                          <span>{source.fields_count} champ{source.fields_count > 1 ? 's' : ''}</span>
                        </>
                      )}
                      {/* PH-S02.1: Statut FTP */}
                      {['ftp_csv', 'ftp_xml', 'http_file'].includes(source.source_type_ext) && (
                        <>
                          <span className="text-slate-600">•</span>
                          <span className={`flex items-center gap-1 ${
                            source.connection_status === 'connected' ? 'text-green-400' :
                            source.connection_status === 'error' ? 'text-red-400' : 'text-slate-500'
                          }`}>
                            <Plug className="h-3.5 w-3.5" />
                            {source.connection_status === 'connected' ? 'FTP connecte' :
                             source.connection_status === 'error' ? 'Erreur FTP' : 'FTP non configure'}
                          </span>
                          {source.selected_files_count > 0 && (
                            <>
                              <span className="text-slate-600">•</span>
                              <span className="flex items-center gap-1 text-primary-400">
                                <File className="h-3.5 w-3.5" />
                                {source.selected_files_count} fichier{source.selected_files_count > 1 ? 's' : ''}
                              </span>
                            </>
                          )}
                        </>
                      )}
                    </div>
                  </div>
                  
                  {/* Actions */}
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => openSourceDetail(source)}
                      className="p-2 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg transition-colors"
                      title="Voir les details"
                    >
                      <Eye className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => deleteSource(source.id)}
                      className="p-2 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                      title="Supprimer"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Wizard Modal */}
      {showWizard && (
        <WizardModal
          step={wizardStep}
          totalSteps={totalSteps}
          data={wizardData}
          onStepChange={setWizardStep}
          onDataChange={setWizardData}
          onClose={closeWizard}
          onSubmit={createSource}
          createError={createError}
          isCreating={isCreating}
          onClearError={() => setCreateError(null)}
        />
      )}

      {/* Detail Modal */}
      {showDetail && selectedSource && (
        <DetailModal
          source={selectedSource}
          onClose={() => {
            setShowDetail(false);
            setSelectedSource(null);
          }}
          onStatusChange={(status) => updateSourceStatus(selectedSource.id, status)}
          onDelete={() => deleteSource(selectedSource.id)}
          onRefresh={loadSources}
        />
      )}
    </div>
  );
}

// ============================================
// WIZARD MODAL (avec FTP integre)
// ============================================

interface WizardModalProps {
  step: number;
  totalSteps: number;
  data: {
    kind: SourceKind | null;
    type: SourceTypeExtended | null;
    ftpProtocol: 'ftp' | 'sftp';
    ftpHost: string;
    ftpPort: number;
    ftpUsername: string;
    ftpPassword: string;
    ftpConnected: boolean;
    secretRefId: string;
    selectedFiles: { path: string; filename: string }[];
    detectedHeaders: DetectedHeader[];
    columnMappings: ColumnMapping[];
    name: string;
    description: string;
    priority: number;
    fields: { code: string; label: string; required: boolean }[];
  };
  onStepChange: (step: number) => void;
  onDataChange: (data: any) => void;
  onClose: () => void;
  onSubmit: () => void;
  createError?: string | null;
  isCreating?: boolean;
  onClearError?: () => void;
}

function WizardModal({ step, totalSteps, data, onStepChange, onDataChange, onClose, onSubmit, createError, isCreating, onClearError }: WizardModalProps) {
  // FTP state
  const [isTesting, setIsTesting] = useState(false);
  const [testMessage, setTestMessage] = useState<string | null>(null);
  const [testSuccess, setTestSuccess] = useState(false);
  
  // File browser state
  const [currentPath, setCurrentPath] = useState('/');
  const [parentPath, setParentPath] = useState<string | null>(null);
  const [items, setItems] = useState<FtpFileItem[]>([]);
  const [isLoadingBrowse, setIsLoadingBrowse] = useState(false);
  const [browseError, setBrowseError] = useState<string | null>(null);
  // Temporary source ID for FTP operations during wizard
  const [tempSourceId, setTempSourceId] = useState<string | null>(null);
  
  // PH-S02.2: Column mapping state
  const [isDetectingHeaders, setIsDetectingHeaders] = useState(false);
  const [detectError, setDetectError] = useState<string | null>(null);
  const [availableFields, setAvailableFields] = useState<ProductFieldOption[]>([]);
  // PH-S03.2: Liste des secret refs (FTP_CREDENTIALS) pour connexion durable
  const [secretRefs, setSecretRefs] = useState<{ id: string; name: string; refType: string }[]>([]);

  const needsFtp = data.type ? SOURCE_TYPE_CONFIG[data.type]?.needsFtp : false;

  useEffect(() => {
    if (needsFtp && step === 3) {
      api.get<{ id: string; name: string; refType: string }[]>('/api/secret-refs').then(setSecretRefs).catch(() => setSecretRefs([]));
    }
  }, [needsFtp, step]);
  
  const availableTypes = data.kind
    ? Object.entries(SOURCE_TYPE_CONFIG)
        .filter(([_, config]) => config.forKinds.includes(data.kind!))
        .map(([key]) => key as SourceTypeExtended)
    : [];

  // Determine actual step mapping based on whether FTP is needed
  // PH-S03.4: If needsFtp: 1=kind, 2=type, 3=ftp, 4=files, 5=finalize (no mapping step)
  // If !needsFtp: 1=kind, 2=type, 3=finalize
  
  // PH-S03.4: Wizard sans étape mapping (5=Finalisation avec FTP)
  const getStepTitle = () => {
    if (needsFtp) {
      switch (step) {
        case 1: return "D'ou viennent vos produits ?";
        case 2: return "Type de source";
        case 3: return "Connexion au serveur";
        case 4: return "Selection des fichiers";
        case 5: return "Finalisation";
        default: return "";
      }
    } else {
      switch (step) {
        case 1: return "D'ou viennent vos produits ?";
        case 2: return "Type de source";
        case 3: return "Finalisation";
        default: return "";
      }
    }
  };

  function toggleField(code: string, label: string, defaultRequired: boolean) {
    const exists = data.fields.find(f => f.code === code);
    if (exists) {
      onDataChange({ ...data, fields: data.fields.filter(f => f.code !== code) });
    } else {
      onDataChange({ ...data, fields: [...data.fields, { code, label, required: defaultRequired }] });
    }
  }

  function toggleFieldRequired(code: string) {
    onDataChange({
      ...data,
      fields: data.fields.map(f => f.code === code ? { ...f, required: !f.required } : f)
    });
  }

  // FTP Test Connection - Appel API reel
  async function testFtpConnection() {
    if (!data.ftpHost) return;
    
    setIsTesting(true);
    setTestMessage(null);
    setTestSuccess(false);
    
    try {
      // Appel API direct (sans source existante)
      const response = await api.post<{ success: boolean; message: string }>('/api/ftp/test-direct', {
        protocol: data.ftpProtocol,
        host: data.ftpHost,
        port: data.ftpPort,
        username: data.ftpUsername || null,
        password: data.ftpPassword || null,
      });
      
      if (response.success) {
        setTestSuccess(true);
        setTestMessage(response.message || 'Connexion reussie !');
        onDataChange({ ...data, ftpConnected: true });
      } else {
        setTestSuccess(false);
        setTestMessage(response.message || 'Echec de la connexion');
        onDataChange({ ...data, ftpConnected: false });
      }
      
    } catch (err) {
      setTestSuccess(false);
      setTestMessage(err instanceof Error ? err.message : 'Erreur de connexion');
      onDataChange({ ...data, ftpConnected: false });
    } finally {
      setIsTesting(false);
    }
  }

  // Browse FTP - Appel API reel
  async function browseFtp(path: string) {
    setIsLoadingBrowse(true);
    setBrowseError(null);
    
    try {
      // Appel API direct (sans source existante)
      const response = await api.post<{ current_path: string; items: FtpFileItem[]; parent_path: string | null }>('/api/ftp/browse-direct', {
        protocol: data.ftpProtocol,
        host: data.ftpHost,
        port: data.ftpPort,
        username: data.ftpUsername || null,
        password: data.ftpPassword || null,
        path: path,
      });
      
      setCurrentPath(response.current_path);
      setParentPath(response.parent_path);
      setItems(response.items || []);
      
    } catch (err) {
      setBrowseError(err instanceof Error ? err.message : 'Erreur de navigation FTP');
    } finally {
      setIsLoadingBrowse(false);
    }
  }

  function toggleFileSelection(path: string, filename: string) {
    const exists = data.selectedFiles.find(f => f.path === path);
    if (exists) {
      onDataChange({ ...data, selectedFiles: data.selectedFiles.filter(f => f.path !== path) });
    } else {
      onDataChange({ ...data, selectedFiles: [...data.selectedFiles, { path, filename }] });
    }
  }

  // PH-S02.2: Detecter les en-tetes du fichier CSV
  async function detectHeaders() {
    if (data.selectedFiles.length === 0) return;
    
    setIsDetectingHeaders(true);
    setDetectError(null);
    
    try {
      // Detecter les en-tetes du premier fichier selectionne
      const response = await api.post<{
        success: boolean;
        headers: DetectedHeader[];
        detected_delimiter: string;
        error?: string;
      }>('/api/column-mapping/detect-headers-direct', {
        protocol: data.ftpProtocol,
        host: data.ftpHost,
        port: data.ftpPort,
        username: data.ftpUsername || null,
        password: data.ftpPassword || null,
        file_path: data.selectedFiles[0].path,
        encoding: 'utf-8',
        has_header_row: true,
      });
      
      if (response.success) {
        onDataChange({ ...data, detectedHeaders: response.headers });
      } else {
        setDetectError(response.error || 'Erreur lors de la detection');
      }
      
      // Charger les champs disponibles
      const fieldsResponse = await api.get<{ fields: ProductFieldOption[] }>('/api/column-mapping/available-fields');
      setAvailableFields(fieldsResponse.fields);
      
    } catch (err) {
      setDetectError(err instanceof Error ? err.message : 'Erreur lors de la detection');
    } finally {
      setIsDetectingHeaders(false);
    }
  }

  // PH-S02.2: Ajouter/Modifier un mapping
  function setMapping(headerIndex: number, headerName: string, targetField: string, targetFieldLabel: string) {
    const newMappings = data.columnMappings.filter(m => m.sourceColumnIndex !== headerIndex);
    if (targetField) {
      newMappings.push({
        sourceColumn: headerName,
        sourceColumnIndex: headerIndex,
        targetField,
        targetFieldLabel,
      });
    }
    onDataChange({ ...data, columnMappings: newMappings });
  }

  // PH-S02.2: Obtenir le mapping pour un header
  function getMappingForHeader(headerIndex: number): ColumnMapping | undefined {
    return data.columnMappings.find(m => m.sourceColumnIndex === headerIndex);
  }

  // PH-S02.2: Verifier si un champ est deja mappe
  function isFieldMapped(fieldCode: string): boolean {
    return data.columnMappings.some(m => m.targetField === fieldCode);
  }

  function isFileSelected(path: string) {
    return data.selectedFiles.some(f => f.path === path);
  }

  // PH-S03.4: step 5 = Finalisation (plus de mapping dans le wizard)
  function canProceed() {
    if (needsFtp) {
      switch (step) {
        case 1: return !!data.kind;
        case 2: return !!data.type;
        case 3: return data.ftpConnected;
        case 4: return data.selectedFiles.length > 0;
        case 5: return !!data.name;
        default: return false;
      }
    } else {
      switch (step) {
        case 1: return !!data.kind;
        case 2: return !!data.type;
        case 3: return !!data.name;
        default: return false;
      }
    }
  }

  function handleNext() {
    if (step < totalSteps) {
      onStepChange(step + 1);
      // Reset FTP browse when entering step 4
      if (needsFtp && step === 3) {
        setCurrentPath('/');
        setItems([]);
        browseFtp('/');
      }
      // PH-S03.4: Plus d'auto-détection des en-têtes dans le wizard — mapping dans onglet "Colonnes (CSV)" après création
    }
  }

  function handleBack() {
    if (step > 1) {
      onStepChange(step - 1);
    } else {
      onClose();
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-700 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-white">
              Nouvelle source de produits
            </h2>
            <p className="text-sm text-slate-400">
              Etape {step} sur {totalSteps} — {getStepTitle()}
            </p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Progress */}
        <div className="px-6 py-3 border-b border-slate-700/50">
          <div className="flex items-center gap-2">
            {Array.from({ length: totalSteps }, (_, i) => i + 1).map((s) => (
              <div key={s} className="flex items-center flex-1">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  s < step ? 'bg-primary-600 text-white' :
                  s === step ? 'bg-primary-600 text-white' :
                  'bg-slate-700 text-slate-400'
                }`}>
                  {s < step ? <CheckCircle2 className="h-5 w-5" /> : s}
                </div>
                {s < totalSteps && (
                  <div className={`flex-1 h-0.5 mx-2 ${s < step ? 'bg-primary-600' : 'bg-slate-700'}`} />
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Step 1: Origin */}
          {step === 1 && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                {(Object.entries(SOURCE_KIND_CONFIG) as [SourceKind, typeof SOURCE_KIND_CONFIG.supplier][]).map(([kind, config]) => {
                  const Icon = config.icon;
                  const isSelected = data.kind === kind;
                  
                  return (
                    <button
                      key={kind}
                      onClick={() => onDataChange({ ...data, kind, type: null, ftpConnected: false, selectedFiles: [] })}
                      className={`p-4 rounded-xl border text-left transition-all ${
                        isSelected
                          ? `${config.bg} ${config.border} border-2`
                          : 'bg-slate-700/50 border-slate-600 hover:border-slate-500'
                      }`}
                    >
                      <Icon className={`h-8 w-8 ${config.color} mb-3`} />
                      <h4 className="font-medium text-white">{config.label}</h4>
                      <p className="text-sm text-slate-400 mt-1">{config.description}</p>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Step 2: Type */}
          {step === 2 && (
            <div className="space-y-4">
              <div className="space-y-3">
                {availableTypes.map((type) => {
                  const config = SOURCE_TYPE_CONFIG[type];
                  const Icon = config.icon;
                  const isSelected = data.type === type;
                  
                  return (
                    <button
                      key={type}
                      onClick={() => onDataChange({ 
                        ...data, 
                        type, 
                        ftpConnected: false, 
                        selectedFiles: [],
                        ftpPort: type === 'ftp_csv' || type === 'ftp_xml' ? 21 : 80
                      })}
                      className={`w-full p-4 rounded-xl border text-left transition-all flex items-center gap-4 ${
                        isSelected
                          ? 'bg-primary-600/10 border-primary-500/50 border-2'
                          : 'bg-slate-700/50 border-slate-600 hover:border-slate-500'
                      }`}
                    >
                      <Icon className={`h-6 w-6 ${isSelected ? 'text-primary-400' : 'text-slate-400'}`} />
                      <div>
                        <h4 className={`font-medium ${isSelected ? 'text-white' : 'text-slate-300'}`}>
                          {config.label}
                        </h4>
                        <p className="text-sm text-slate-400">{config.description}</p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Step 3: FTP Connection (if needed) */}
          {needsFtp && step === 3 && (
            <div className="space-y-6">
              <p className="text-slate-400">
                Configurez la connexion a votre serveur FTP pour acceder a vos fichiers.
              </p>
              
              {/* Connection form */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Protocole
                  </label>
                  <select
                    value={data.ftpProtocol}
                    onChange={(e) => onDataChange({ 
                      ...data, 
                      ftpProtocol: e.target.value as 'ftp' | 'sftp',
                      ftpPort: e.target.value === 'sftp' ? 22 : 21,
                      ftpConnected: false
                    })}
                    className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                  >
                    <option value="ftp">FTP</option>
                    <option value="sftp">SFTP (securise)</option>
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    <Server className="inline h-4 w-4 mr-1" />
                    Serveur
                  </label>
                  <input
                    type="text"
                    value={data.ftpHost}
                    onChange={(e) => onDataChange({ ...data, ftpHost: e.target.value, ftpConnected: false })}
                    className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                    placeholder="ftp.example.com"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    <Hash className="inline h-4 w-4 mr-1" />
                    Port
                  </label>
                  <input
                    type="number"
                    value={data.ftpPort}
                    onChange={(e) => onDataChange({ ...data, ftpPort: parseInt(e.target.value) || 21, ftpConnected: false })}
                    className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    <User className="inline h-4 w-4 mr-1" />
                    Utilisateur
                  </label>
                  <input
                    type="text"
                    value={data.ftpUsername}
                    onChange={(e) => onDataChange({ ...data, ftpUsername: e.target.value, ftpConnected: false })}
                    className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                    placeholder="username"
                  />
                </div>
                
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    <Lock className="inline h-4 w-4 mr-1" />
                    Mot de passe
                  </label>
                  <input
                    type="password"
                    value={data.ftpPassword}
                    onChange={(e) => onDataChange({ ...data, ftpPassword: e.target.value, ftpConnected: false })}
                    className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                    placeholder="••••••••"
                  />
                </div>
              </div>
              
              {/* Test button */}
              <div className="flex items-center gap-4">
                <button
                  onClick={testFtpConnection}
                  disabled={!data.ftpHost || isTesting}
                  className="flex items-center gap-2 px-5 py-2.5 bg-slate-700 text-white rounded-lg hover:bg-slate-600 transition-colors disabled:opacity-50"
                >
                  {isTesting ? (
                    <Loader2 className="h-5 w-5 animate-spin" />
                  ) : (
                    <Plug className="h-5 w-5" />
                  )}
                  Tester la connexion
                </button>
                
                {testMessage && (
                  <span className={`flex items-center gap-2 text-sm ${testSuccess ? 'text-green-400' : 'text-red-400'}`}>
                    {testSuccess ? <CheckCircle2 className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
                    {testMessage}
                  </span>
                )}
              </div>
              
              {/* Status */}
              {data.ftpConnected && (
                <div className="p-4 bg-green-500/10 border border-green-500/20 rounded-lg">
                  <div className="flex items-center gap-2 text-green-400">
                    <CheckCircle2 className="h-5 w-5" />
                    <span className="font-medium">Connexion etablie</span>
                  </div>
                  <p className="text-sm text-green-400/80 mt-1">
                    Vous pouvez maintenant parcourir vos fichiers.
                  </p>
                </div>
              )}

              {/* PH-S03.2: Connexion durable (secret_ref) — optionnel pour wizard */}
              <div className="p-4 bg-slate-700/50 rounded-lg border border-slate-600 mt-4">
                <h4 className="text-sm font-medium text-slate-300 mb-2">Connexion durable (recommandee)</h4>
                <p className="text-xs text-slate-500 mb-3">
                  Choisissez un secret existant pour enregistrer la connexion. Sans secret, la source restera &quot;A completer&quot; et vous pourrez configurer la connexion depuis la fiche source.
                </p>
                <select
                  value={data.secretRefId}
                  onChange={(e) => onDataChange({ ...data, secretRefId: e.target.value })}
                  className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                >
                  <option value="">— Aucun (completer plus tard) —</option>
                  {secretRefs.filter((s) => s.refType === 'FTP_CREDENTIALS').map((s) => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
                </select>
              </div>
            </div>
          )}

          {/* Step 4: File Selection (if FTP) */}
          {needsFtp && step === 4 && (
            <div className="space-y-4">
              <p className="text-slate-400">
                Parcourez votre serveur et selectionnez les fichiers a utiliser.
              </p>
              
              {/* Current path */}
              <div className="flex items-center gap-2 text-sm">
                <span className="text-slate-400">Chemin:</span>
                <code className="px-2 py-1 bg-slate-700 rounded text-slate-300">{currentPath}</code>
                {parentPath !== null && (
                  <button
                    onClick={() => browseFtp(parentPath)}
                    className="flex items-center gap-1 text-primary-400 hover:text-primary-300"
                  >
                    <ChevronLeft className="h-4 w-4" />
                    Retour
                  </button>
                )}
                <button
                  onClick={() => browseFtp(currentPath)}
                  disabled={isLoadingBrowse}
                  className="ml-auto p-1 text-slate-400 hover:text-white"
                >
                  <RefreshCw className={`h-4 w-4 ${isLoadingBrowse ? 'animate-spin' : ''}`} />
                </button>
              </div>
              
              {/* Error */}
              {browseError && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
                  {browseError}
                </div>
              )}
              
              {/* File list */}
              <div className="bg-slate-700/50 rounded-lg divide-y divide-slate-700 max-h-64 overflow-y-auto">
                {isLoadingBrowse ? (
                  <div className="flex items-center justify-center p-8">
                    <Loader2 className="h-6 w-6 animate-spin text-primary-500" />
                  </div>
                ) : items.length === 0 ? (
                  <div className="p-8 text-center text-slate-500">
                    Aucun fichier trouve
                  </div>
                ) : (
                  items.map((item) => (
                    <div
                      key={item.path}
                      className="flex items-center gap-3 p-3 hover:bg-slate-700 transition-colors"
                    >
                      {item.type === 'directory' ? (
                        <>
                          <Folder className="h-5 w-5 text-yellow-400 flex-shrink-0" />
                          <button
                            onClick={() => browseFtp(item.path)}
                            className="flex-1 text-left text-white hover:text-primary-400"
                          >
                            {item.name}
                          </button>
                          <ChevronRight className="h-4 w-4 text-slate-500" />
                        </>
                      ) : (
                        <>
                          <File className={`h-5 w-5 flex-shrink-0 ${isFileSelected(item.path) ? 'text-green-400' : 'text-slate-400'}`} />
                          <span className="flex-1 text-slate-300">{item.name}</span>
                          {item.size && (
                            <span className="text-xs text-slate-500">
                              {(item.size / 1024).toFixed(1)} Ko
                            </span>
                          )}
                          <button
                            onClick={() => toggleFileSelection(item.path, item.name)}
                            className={`px-3 py-1 text-xs rounded transition-colors ${
                              isFileSelected(item.path)
                                ? 'bg-green-500/20 text-green-400'
                                : 'bg-slate-600 text-slate-300 hover:bg-primary-600 hover:text-white'
                            }`}
                          >
                            {isFileSelected(item.path) ? '✓ Selectionne' : 'Selectionner'}
                          </button>
                        </>
                      )}
                    </div>
                  ))
                )}
              </div>
              
              {/* Selected files summary */}
              {data.selectedFiles.length > 0 && (
                <div className="p-4 bg-primary-500/10 border border-primary-500/20 rounded-lg">
                  <h4 className="font-medium text-white mb-2">
                    {data.selectedFiles.length} fichier{data.selectedFiles.length > 1 ? 's' : ''} selectionne{data.selectedFiles.length > 1 ? 's' : ''}
                  </h4>
                  <div className="space-y-1">
                    {data.selectedFiles.map((file) => (
                      <div key={file.path} className="flex items-center gap-2 text-sm text-slate-300">
                        <File className="h-4 w-4 text-primary-400" />
                        <span className="flex-1 truncate">{file.path}</span>
                        <button
                          onClick={() => toggleFileSelection(file.path, file.filename)}
                          className="text-slate-400 hover:text-red-400"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Step 3 (no FTP) or Step 5 (with FTP): Finalize — PH-S03.4 wizard sans étape mapping */}
          {((needsFtp && step === 5) || (!needsFtp && step === 3)) && (
            <div className="space-y-6">
              {/* Erreur de creation */}
              {createError && (
                <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg flex items-start gap-3">
                  <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
                  <div className="flex-1">
                    <p className="text-red-400 font-medium">Erreur lors de la creation</p>
                    <p className="text-red-400/80 text-sm mt-1">{createError}</p>
                  </div>
                  <button onClick={onClearError} className="text-red-400 hover:text-red-300">
                    <X className="h-4 w-4" />
                  </button>
                </div>
              )}

              {/* Name */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Nom de la source *
                </label>
                <input
                  type="text"
                  value={data.name}
                  onChange={(e) => {
                    onDataChange({ ...data, name: e.target.value });
                    // Effacer l'erreur quand l'utilisateur modifie le nom
                    if (createError && onClearError) onClearError();
                  }}
                  className={`w-full px-4 py-2.5 bg-slate-700 border rounded-lg text-white ${
                    createError ? 'border-red-500/50' : 'border-slate-600'
                  }`}
                  placeholder="Ex: Catalogue Fournisseur ABC"
                />
              </div>
              
              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Description
                </label>
                <textarea
                  value={data.description}
                  onChange={(e) => onDataChange({ ...data, description: e.target.value })}
                  className="w-full px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white resize-none"
                  rows={2}
                  placeholder="Description optionnelle..."
                />
              </div>
              
              {/* Priority */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Priorite
                  <span className="ml-2 text-xs text-slate-500">
                    (1-999, plus petit = plus prioritaire)
                  </span>
                </label>
                <input
                  type="number"
                  value={data.priority}
                  onChange={(e) => onDataChange({ ...data, priority: Math.max(1, Math.min(999, parseInt(e.target.value) || 100)) })}
                  className="w-32 px-4 py-2.5 bg-slate-700 border border-slate-600 rounded-lg text-white"
                  min={1}
                  max={999}
                />
              </div>
              
              {/* Fields */}
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-3">
                  Champs produits attendus
                </label>
                <div className="space-y-2">
                  {FIELD_CODE_OPTIONS.map((option) => {
                    const field = data.fields.find(f => f.code === option.code);
                    const isSelected = !!field;
                    
                    return (
                      <div
                        key={option.code}
                        className={`p-3 rounded-lg border transition-colors ${
                          isSelected
                            ? 'bg-primary-600/10 border-primary-500/50'
                            : 'bg-slate-700/50 border-slate-600 hover:border-slate-500'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleField(option.code, option.label, option.default_required)}
                            className="w-4 h-4 rounded border-slate-500 text-primary-600 focus:ring-primary-500 bg-slate-700"
                          />
                          <div className="flex-1">
                            <span className={isSelected ? 'text-white' : 'text-slate-300'}>
                              {option.label}
                            </span>
                            {option.default_required && (
                              <span className="ml-2 text-xs text-yellow-400">(recommande)</span>
                            )}
                          </div>
                          {isSelected && (
                            <label className="flex items-center gap-2 text-sm">
                              <input
                                type="checkbox"
                                checked={field?.required || false}
                                onChange={() => toggleFieldRequired(option.code)}
                                className="w-3.5 h-3.5 rounded border-slate-500 text-primary-600 focus:ring-primary-500 bg-slate-700"
                              />
                              <span className="text-slate-400">Obligatoire</span>
                            </label>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
              
              {/* Summary */}
              {needsFtp && data.selectedFiles.length > 0 && (
                <div className="p-4 bg-slate-700/50 rounded-lg">
                  <h4 className="text-sm font-medium text-slate-400 mb-2">Resume</h4>
                  <div className="space-y-1 text-sm">
                    <div className="flex items-center gap-2 text-white">
                      <Plug className="h-4 w-4 text-green-400" />
                      FTP connecte: {data.ftpHost}
                    </div>
                    <div className="flex items-center gap-2 text-white">
                      <File className="h-4 w-4 text-primary-400" />
                      {data.selectedFiles.length} fichier{data.selectedFiles.length > 1 ? 's' : ''} selectionne{data.selectedFiles.length > 1 ? 's' : ''}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-700 flex items-center justify-between">
          <button
            onClick={handleBack}
            className="flex items-center gap-2 px-4 py-2 text-slate-300 hover:text-white transition-colors"
          >
            <ChevronLeft className="h-4 w-4" />
            {step > 1 ? 'Retour' : 'Annuler'}
          </button>
          
          {step < totalSteps ? (
            <button
              onClick={handleNext}
              disabled={!canProceed()}
              className="flex items-center gap-2 px-5 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Continuer
              <ChevronRight className="h-4 w-4" />
            </button>
          ) : (
            <button
              onClick={onSubmit}
              disabled={!canProceed() || isCreating}
              className="flex items-center gap-2 px-5 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isCreating ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Creation en cours...
                </>
              ) : (
                <>
                  <CheckCircle2 className="h-4 w-4" />
                  Creer la source
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================
// PH-S03.4: Onglet "Colonnes (CSV)" — détection + mapping après création
// ============================================

interface SelectedFileRow {
  id: string;
  remote_path: string;
  filename: string;
  selected: boolean;
}

interface SourceColumnMappingTabProps {
  sourceId: string;
  onRefresh: () => void;
}

function SourceColumnMappingTab({ sourceId, onRefresh }: SourceColumnMappingTabProps) {
  const [files, setFiles] = useState<SelectedFileRow[]>([]);
  const [selectedFilePath, setSelectedFilePath] = useState('');
  const [detectedHeaders, setDetectedHeaders] = useState<DetectedHeader[]>([]);
  const [mappings, setMappings] = useState<Record<number, { targetField: string; targetFieldLabel: string }>>({});
  const [availableFields, setAvailableFields] = useState<ProductFieldOption[]>([]);
  const [isDetecting, setIsDetecting] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.get<SelectedFileRow[]>(`/api/catalog-sources/${sourceId}/ftp/files`)
      .then((list) => {
        const selected = list.filter((f) => f.selected);
        setFiles(selected);
        if (selected.length > 0 && !selectedFilePath) {
          setSelectedFilePath(selected[0].remote_path);
        }
      })
      .catch(() => setFiles([]));
    api.get<{ fields: ProductFieldOption[] }>('/api/column-mapping/available-fields')
      .then((r) => setAvailableFields(r.fields))
      .catch(() => setAvailableFields([]));
  }, [sourceId, selectedFilePath]);

  async function handleDetect() {
    if (!selectedFilePath) return;
    setIsDetecting(true);
    setError(null);
    try {
      const res = await api.post<{ success: boolean; headers: DetectedHeader[]; error?: string }>(
        `/api/catalog-sources/${sourceId}/column-mappings/detect-headers`,
        { file_path: selectedFilePath, encoding: 'utf-8', has_header_row: true }
      );
      if (res.success) {
        setDetectedHeaders(res.headers);
        setMappings({});
      } else {
        setError(res.error || 'Erreur lors de la detection');
      }
    } catch (err) {
      setError(getDisplayErrorMessage(err));
    } finally {
      setIsDetecting(false);
    }
  }

  function setMapping(headerIndex: number, targetField: string) {
    const field = availableFields.find((f) => f.field === targetField);
    setMappings((prev) => ({
      ...prev,
      [headerIndex]: targetField ? { targetField, targetFieldLabel: field?.label || targetField } : { targetField: '', targetFieldLabel: '' },
    }));
  }

  async function handleSaveMapping() {
    const list = Object.entries(mappings)
      .filter(([, v]) => v.targetField)
      .map(([idx, v]) => ({
        source_column: detectedHeaders[Number(idx)]?.name || '',
        source_column_index: Number(idx),
        target_field: v.targetField === 'stock' ? 'quantity' : v.targetField,
      }));
    if (list.length === 0) {
      setError('Configurez au moins un mapping (SKU obligatoire).');
      return;
    }
    if (!list.some((m) => m.target_field === 'sku')) {
      setError('Le champ SKU est obligatoire.');
      return;
    }
    setIsSaving(true);
    setError(null);
    try {
      await api.post(`/api/catalog-sources/${sourceId}/column-mappings/bulk`, { mappings: list });
      onRefresh();
    } catch (err) {
      setError(getDisplayErrorMessage(err));
    } finally {
      setIsSaving(false);
    }
  }

  const hasSku = Object.values(mappings).some((v) => v.targetField === 'sku');

  return (
    <div className="space-y-4">
      <h3 className="text-sm font-medium text-slate-400">Mapping colonnes CSV → champs produit</h3>
      {files.length === 0 ? (
        <p className="text-slate-500">Aucun fichier selectionne. Configurez la connexion FTP et selectionnez des fichiers dans l&apos;onglet Connexion FTP.</p>
      ) : (
        <>
          <div>
            <label className="block text-sm text-slate-400 mb-2">Fichier pour la detection</label>
            <select
              value={selectedFilePath}
              onChange={(e) => setSelectedFilePath(e.target.value)}
              className="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white"
            >
              {files.map((f) => (
                <option key={f.id} value={f.remote_path}>{f.remote_path}</option>
              ))}
            </select>
          </div>
          <button
            onClick={handleDetect}
            disabled={isDetecting || !selectedFilePath}
            className="flex items-center gap-2 px-4 py-2 bg-slate-700 text-white rounded-lg hover:bg-slate-600 disabled:opacity-50"
          >
            {isDetecting ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            Detecter les colonnes
          </button>
          {error && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">{error}</div>
          )}
          {detectedHeaders.length > 0 && (
            <>
              <div className="bg-slate-700/50 rounded-lg divide-y divide-slate-700 max-h-64 overflow-y-auto">
                {detectedHeaders.map((h) => (
                  <div key={h.index} className="p-3 flex items-center gap-4">
                    <span className="flex-1 text-white truncate">{h.name || `Colonne ${h.index + 1}`}</span>
                    <ChevronRight className="h-4 w-4 text-slate-500" />
                    <select
                      value={mappings[h.index]?.targetField || ''}
                      onChange={(e) => setMapping(h.index, e.target.value)}
                      className="w-48 px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm"
                    >
                      <option value="">— Ignorer —</option>
                      {availableFields.map((f) => (
                        <option key={f.field} value={f.field}>{f.label}{f.required ? ' *' : ''}</option>
                      ))}
                    </select>
                  </div>
                ))}
              </div>
              <div className="flex items-center gap-2">
                {hasSku ? (
                  <span className="text-green-400 text-sm flex items-center gap-1"><CheckCircle2 className="h-4 w-4" /> SKU configure</span>
                ) : (
                  <span className="text-yellow-400 text-sm flex items-center gap-1"><AlertTriangle className="h-4 w-4" /> SKU obligatoire</span>
                )}
                <button
                  onClick={handleSaveMapping}
                  disabled={isSaving || !hasSku}
                  className="ml-auto flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50"
                >
                  {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                  Enregistrer le mapping
                </button>
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}

// ============================================
// DETAIL MODAL (pour sources existantes)
// ============================================

interface DetailModalProps {
  source: CatalogSource;
  onClose: () => void;
  onStatusChange: (status: SourceStatus) => void;
  onDelete: () => void;
  onRefresh: () => void;
}

function DetailModal({ source, onClose, onStatusChange, onDelete, onRefresh }: DetailModalProps) {
  const [activeTab, setActiveTab] = useState<'infos' | 'ftp' | 'columns'>('infos');
  const kindConfig = SOURCE_KIND_CONFIG[source.source_kind] || SOURCE_KIND_CONFIG.supplier;
  const statusConfig = STATUS_CONFIG[source.status] || STATUS_CONFIG.to_complete;
  const KindIcon = kindConfig.icon;
  const StatusIcon = statusConfig.icon;
  
  const supportsFtp = ['ftp_csv', 'ftp_xml', 'http_file'].includes(source.source_type_ext);
  const connStatus = {
    not_configured: { label: 'Non configure', color: 'text-slate-400' },
    connected: { label: 'Connecte', color: 'text-green-400' },
    error: { label: 'Erreur', color: 'text-red-400' },
  }[source.connection_status] || { label: 'Non configure', color: 'text-slate-400' };

  const tabs = [
    { id: 'infos' as const, label: 'Infos' },
    ...(supportsFtp ? [{ id: 'ftp' as const, label: 'Connexion FTP' }, { id: 'columns' as const, label: 'Colonnes (CSV)' }] : []),
  ];

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-700 flex items-center gap-4">
          <div className={`p-3 rounded-xl ${kindConfig.bg} ${kindConfig.border} border`}>
            <KindIcon className={`h-6 w-6 ${kindConfig.color}`} />
          </div>
          <div className="flex-1">
            <h2 className="text-lg font-semibold text-white">{source.name}</h2>
            <p className="text-sm text-slate-400">{kindConfig.label}</p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Tabs — PH-S03.4 */}
        {tabs.length > 1 && (
          <div className="flex border-b border-slate-700 px-6">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-primary-500 text-white'
                    : 'border-transparent text-slate-400 hover:text-slate-300'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        )}

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {activeTab === 'ftp' && supportsFtp && (
            <FtpConnection
              sourceId={source.id}
              connectionStatus={source.connection_status}
              selectedFilesCount={source.selected_files_count}
              onRefresh={onRefresh}
            />
          )}

          {activeTab === 'columns' && supportsFtp && (
            <SourceColumnMappingTab sourceId={source.id} onRefresh={onRefresh} />
          )}

          {activeTab === 'infos' && (
            <>
          {/* Status */}
          <div>
            <h3 className="text-sm font-medium text-slate-400 mb-3">Statut</h3>
            <div className="flex items-center gap-3">
              <span className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium ${statusConfig.bg} ${statusConfig.color} ${statusConfig.border} border`}>
                <StatusIcon className="h-4 w-4" />
                {statusConfig.label}
              </span>
              
              {source.status !== 'disabled' && (
                <button
                  onClick={() => onStatusChange('disabled')}
                  className="text-sm text-slate-400 hover:text-white"
                >
                  Desactiver
                </button>
              )}
              {source.status === 'disabled' && (
                <button
                  onClick={() => onStatusChange('ready')}
                  className="text-sm text-primary-400 hover:text-primary-300"
                >
                  Activer
                </button>
              )}
            </div>
          </div>

          {/* Info */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <h3 className="text-sm font-medium text-slate-400 mb-1">Type</h3>
              <p className="text-white">{SOURCE_TYPE_CONFIG[source.source_type_ext]?.label || source.source_type_ext}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-400 mb-1">Priorite</h3>
              <p className="text-white">{source.priority}</p>
            </div>
          </div>

          {source.description && (
            <div>
              <h3 className="text-sm font-medium text-slate-400 mb-1">Description</h3>
              <p className="text-white">{source.description}</p>
            </div>
          )}

          {/* FTP Info */}
          {supportsFtp && (
            <div className="p-4 bg-slate-700/50 rounded-lg">
              <h3 className="text-sm font-medium text-slate-400 mb-3">Connexion FTP</h3>
              <div className="flex items-center gap-4">
                <span className={`flex items-center gap-1.5 ${connStatus.color}`}>
                  <Plug className="h-4 w-4" />
                  {connStatus.label}
                </span>
                {source.selected_files_count > 0 && (
                  <span className="flex items-center gap-1.5 text-primary-400">
                    <File className="h-4 w-4" />
                    {source.selected_files_count} fichier{source.selected_files_count > 1 ? 's' : ''}
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Fields */}
          <div>
            <h3 className="text-sm font-medium text-slate-400 mb-3">
              Champs produits configures ({source.fields_count})
            </h3>
            {source.fields && source.fields.length > 0 ? (
              <div className="space-y-2">
                {source.fields.map((field) => (
                  <div
                    key={field.id}
                    className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg"
                  >
                    <span className="text-white">{field.field_label}</span>
                    {field.required && (
                      <span className="text-xs bg-yellow-500/20 text-yellow-400 px-2 py-0.5 rounded">
                        Obligatoire
                      </span>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-slate-500 italic">Aucun champ configure</p>
            )}
          </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-700 flex items-center justify-between">
          <button
            onClick={onDelete}
            className="flex items-center gap-2 px-4 py-2 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg transition-colors"
          >
            <Trash2 className="h-4 w-4" />
            Supprimer
          </button>
          <button
            onClick={onClose}
            className="px-5 py-2 bg-slate-700 text-white rounded-lg hover:bg-slate-600 transition-colors"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
}
