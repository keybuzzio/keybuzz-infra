# PH-SAAS-T8.12AS.19.6-REGISTER-QA-CGU-STATE-AND-COPY-PROPOSALS-01

> Date : 2026-05-20
> Linear : KEY-335 primary ; KEY-334, KEY-329, KEY-331, KEY-330, KEY-325 related
> Phase : PH-SAAS-T8.12AS.19.6-REGISTER-QA-CGU-STATE-AND-COPY-PROPOSALS (audit + propositions only)
> Environnement : SOURCE READ-ONLY / aucun patch / aucun build / aucun push / aucun deploy

## VERDICT

NO GO BUILD - ATTENTE CHOIX COPY + GO PATCH

- Bug CGU diagnostique : `acceptCgu` est state local React (useState false initial) + checkbox visible UNIQUEMENT dans le step `user` (l.936) + validation `acceptCgu` requise sur step `plan` (l.412 handleConfirmPlanAndCheckout). Toute remontee du component sur step `plan` sans passer par step `user` -> erreur "Vous devez accepter les CGU" sans aucune UI pour decocher/cocher.
- 10 propositions copy 0 EUR / aucun debit produites, classees par style SaaS standard.
- Recommandation CE : Top 3 + patch CGU detaille mais NON applique.
- Aucun build / docker push / kubectl execute.
- Runtime DEV `v3.5.203-register-autopilot-trial-copy-dev` inchange (verifie phase APPLY).

Prochaine phrase GO attendue : choisir copy parmi top 3 puis `GO PATCH CGU + COPY PH-SAAS-T8.12AS.19.6`.

---

## A. DIAGNOSTIC BUG CGU / RETOUR ARRIERE

### A.1 Etat actuel du code (`app/register/page.tsx`)

| Element | Ligne | Comportement |
|---|---|---|
| `acceptCgu` state | 155 | `useState(false)` -- pas de restore sessionStorage |
| Checkbox CGU UI | 936 | Visible uniquement dans le step `user`, avec id "cgu", label CGU + Politique de confidentialite via LegalModal |
| Submit step user disabled | 944 | `disabled={!acceptCgu || !firstName || !lastName}` -- bouton "Continuer vers le plan" |
| Validation handleUserSubmit | 400 | `if (!acceptCgu) { setError('Vous devez accepter les CGU'); return; }` |
| Validation handleConfirmPlanAndCheckout | 412 | `if (!acceptCgu) { setError('Vous devez accepter les CGU'); return; }` -- step plan |
| Payload create-signup | 430 | `cguAccepted: true` (envoye uniquement si validation passe) |
| Step initial | 124 | `useState<Step>(urlStep || (isOAuthUser ? 'company' : 'email'))` -- urlStep peut etre `plan` |
| Persist plan/cycle | 90-101 | `sessionStorage.kb_signup_context` -- pattern existant pour plan/cycle uniquement |
| Persist acceptCgu | -- | AUCUN -- acceptCgu n est jamais persiste |

### A.2 Reproduction du bug

| Scenario | Mount step | acceptCgu | Checkbox visible | Resultat |
|---|---|---|---|---|
| Flow nominal complet | email -> user (coche) -> plan | true | OUI sur step user | OK |
| Refresh F5 sur step plan | mount initial step=plan | false (reset) | NON | Erreur "Vous devez accepter les CGU" sans UI |
| URL externe directe `/register?plan=pro&step=plan` | mount initial step=plan | false | NON | Erreur sans UI |
| Retour Stripe annule | mount initial step=payment_cancelled | false | NON | handleRetryCheckout (l.494+) -- pas de check CGU ici |
| Click "Confirmer" puis change plan (sans remount) | reste sur step=plan | true (preserve) | NON | OK -- selectedPlan change visuellement (PH-19.4 fix) |
| Browser Back depuis Stripe externe puis change plan | varie selon historique | true ou false selon snapshot React | NON | Bug si snapshot acceptCgu = false |

### A.3 Constat Ludovic confirme

Le scenario "revenir en arriere pour changer de plan" couvre essentiellement :
- Cas A : refresh navigateur sur step plan (F5).
- Cas B : retour Stripe annule puis l user change de plan et reclique "Confirmer ce plan" (mais ce passe par step plan, pas payment_cancelled si urlCancelled='1' -> setStep('payment_cancelled') l.492 -- besoin re-verif).
- Cas C : Browser Back depuis Stripe Checkout externe -> retour sur `/register?plan=...` -> mount initial -> selectedPlan retrouve via sessionStorage `kb_signup_context` (deja ecrit avant Stripe) MAIS acceptCgu non persiste -> false -> erreur.
- Cas D : ouverture d un nouveau tab avec URL contenant `step=plan` (partage de lien, history navigateur, etc.).

---

## B. CAUSE RACINE PROBABLE

**Cause racine confirmee** : `acceptCgu` n est PAS persiste dans sessionStorage, contrairement au pattern existant `kb_signup_context` (l.90-101) qui persiste plan/cycle pour OAuth flow.

Consequence directe :
- A chaque mount du composant `RegisterPage` avec un step initial different de `user`, le state `acceptCgu` est reinitialise a `false`.
- Aucune UI ne permet a l utilisateur de cocher CGU s il n est pas sur le step `user`.
- Le CTA "Confirmer ce plan et activer l essai 14 jours" (step plan) declenche la validation `acceptCgu` et echoue silencieusement sans permettre de remediation.
- Le seul recours pour l user est de cliquer sur "Retour aux infos entreprise" (l.948) ... qui n existe que SUR le step user, donc inacessible si le bug se manifeste sur step plan.

**Cause secondaire** : Le pattern PH-19.3 lead-first a deplace `plan` apres `user` (l.541 `stepsOrder: ['email','code','company','user','plan','checkout','payment_cancelled']`), mais la validation CGU n a pas suivi (toujours sur step user via checkbox). Cela amplifie le risque de mount direct sur step plan apres un refresh ou un Back.

---

## C. RECOMMANDATION UX CGU

| Option | Description | Pour | Contre | Reco |
|---|---|---|---|---|
| A | Afficher la checkbox CGU sur step plan en plus du step user | Simple, UI explicite | Redondance UX, double check potentiel | non |
| B | Persist `acceptCgu` dans sessionStorage et restore au mount | Pas de UI dupliquee, transparent | Si user remount et veut decocher, pas d UI accessible (mais low risk apres acceptation explicite) | recommande pour le bug fix immediat |
| C | Persist + petit encart non-bloquant "CGU acceptees" + lien "Voir les CGU" sur step plan | Maximum clarte UX, conforme aux SaaS pros | Patch plus important (UI nouvelle) | meilleur pour QA visible mais plus de travail |
| D | Combiner B + C (persist + encart visible + lien legal modal accessible) | UX optimale | Patch plus grand mais coherent avec PH-19.5 copy clarifie | recommandation finale CE |

**Recommandation CE finale : Option D (persist + encart visible).**

Justification :
- Resout le bug immediat (persist evite acceptCgu=false a chaque mount).
- Cree un signal visuel rassurant sur step plan (l user sait qu il a deja accepte).
- Permet de revoir les CGU sans casser le flow (link modal).
- Reste coherent avec la doctrine PH-19.5 (CTA + microcopy rassurant pre-Stripe).
- N introduit pas de double checkbox redondante.

---

## D. PATCH CGU PROPOSE (fichier par fichier, NON applique)

### D.1 `app/register/page.tsx`

#### D.1.a Restore acceptCgu au mount (sous l.101)

Apres le bloc `kb_signup_context` (l.90-101), ajouter une lecture sessionStorage similaire :

```ts
// PH-SAAS-T8.12AS.19.6 (KEY-335): persist CGU pour eviter erreur "Vous devez accepter les CGU"
// si l utilisateur revient sur step plan apres acceptation initiale.
let initialAcceptCgu = false;
if (typeof window !== 'undefined') {
  try {
    if (sessionStorage.getItem('kb_signup_cgu_accepted') === 'true') {
      initialAcceptCgu = true;
    }
  } catch {}
}
```

#### D.1.b Initialiser useState avec la valeur restauree (l.155)

Remplacer :
```ts
const [acceptCgu, setAcceptCgu] = useState(false);
```
par :
```ts
const [acceptCgu, setAcceptCgu] = useState(initialAcceptCgu);
```

#### D.1.c Persist acceptCgu via useEffect (apres ligne 158)

Ajouter :
```ts
// PH-SAAS-T8.12AS.19.6 (KEY-335): persist CGU dans sessionStorage des qu il est accepte.
useEffect(() => {
  if (typeof window === 'undefined') return;
  try {
    if (acceptCgu) {
      sessionStorage.setItem('kb_signup_cgu_accepted', 'true');
    }
    // Note : on ne supprime pas la cle si decoche. L user qui decoche n a probablement pas
    // termine son signup ; on garde la valeur acceptee pour les futurs flows. Si necessaire,
    // remplacer par : else { sessionStorage.removeItem('kb_signup_cgu_accepted'); }
  } catch {}
}, [acceptCgu]);
```

#### D.1.d Encart "CGU acceptees" sur step plan (avant CTA "Confirmer ce plan", autour l.736 dans le `{selectedPlan && (...)}` block)

Ajouter avant le `<button onClick={handleConfirmPlanAndCheckout}>` :

```tsx
{acceptCgu && (
  <div className="mb-3 flex items-center gap-2 text-xs text-gray-400" data-testid="register-cgu-accepted-note">
    <Check className="h-3 w-3 text-green-400 flex-shrink-0" />
    <span>
      CGU et Politique de confidentialite acceptees.{' '}
      <button type="button" onClick={() => setLegalModal('cgu')} className="text-blue-400 hover:underline">
        Voir les CGU
      </button>
    </span>
  </div>
)}
```

#### D.1.e Cleanup sessionStorage cgu apres success Stripe (apres setStep('checkout') l.461, dans `try` block de handleConfirmPlanAndCheckout)

Optionnel, nettoyage post-flow reussi :
```ts
try {
  sessionStorage.removeItem('kb_signup_cgu_accepted');
  sessionStorage.removeItem('kb_signup_context');
} catch {}
```

### D.2 Aucun autre fichier modifie

- `app/register/LegalModal.tsx` : inchange (deja accessible via setLegalModal('cgu')).
- `src/lib/attribution.ts` : inchange.
- API : aucun changement (`cguAccepted: true` continue d etre envoye dans le payload create-signup).

### D.3 Scope strict du patch propose

| Fichier | Type | Lignes ajoutees | Lignes modifiees |
|---|---|---|---|
| `app/register/page.tsx` | Client React | ~25 (initialAcceptCgu + useEffect persist + encart visuel) | 1 (useState init) |

---

## E. AUDIT COPY ACTUEL

### E.1 Inventaire copy "essai 14 jours / CB / Autopilot / plan choisi / resiliation"

| Ligne | Source | Copy actuel | Note |
|---|---|---|---|
| 264 | header dynamique step user | "Confirmer vos informations puis activer l'essai 14 jours." | OK |
| 265 | header step payment_cancelled | "Reprendre le paiement pour activer votre essai 14 jours." | OK |
| 306 | reassurance step plan (recap) | "Essai gratuit 14 jours - sans engagement - resiliable a tout moment." | OK mais peu visible |
| 575 | header step email | "Avant de regarder les plans, voyons ce que vous obtenez. Aucune CB requise tant que vous n'avez pas confirme." | OK |
| 597 | ReassurancePanel lateral | "Essai 14 jours sur Autopilot, puis bascule sur le plan choisi" | OK |
| 644 | bloc 3 etapes step plan | "Votre choix fixe le plan apres l'essai. Pendant 14 jours, vous testez Autopilot pour voir toute la valeur." | trop verbeux + "vous testez" tres marketing |
| 656 | bloc 3 etapes - titre etape 3 | "Lancez l'essai 14 jours" | OK |
| 663 | sous-titre step plan | "14 jours d'essai gratuit sur Autopilot - puis bascule sur le plan choisi." | OK mais factuel |
| 664-668 | encart bleu register-autopilot-trial-note | "Pendant l'essai, tout le monde teste Autopilot." + "Quel que soit le plan choisi, vous profitez de l'experience la plus complete. A la fin des 14 jours, si vous continuez, KeyBuzz bascule simplement sur le plan selectionne ici. Vous pouvez changer ou resilier pendant l'essai." | "tout le monde teste" trop familier / amateur. Manque le signal financier "0 EUR" qui rassure |
| 729 | sous-titre grille plans | "Facturation annuelle - Essai 14 jours inclus" | OK |
| 745 | CTA principal step plan | "Confirmer ce plan et activer l'essai 14 jours" | OK |
| 748 | microcopy sous CTA | "CB requise a cette etape uniquement. L'essai se fait sur Autopilot ; le plan choisi prend le relais apres 14 jours si vous continuez." | trop technique, pas assez rassurant sur l absence de debit |
| 962 | header step checkout | "Vous allez etre redirige vers Stripe pour activer votre essai de 14 jours." (source: caracteres Unicode dans le code) | OK |
| 980 | header step checkout (cancelled) | "Votre essai gratuit de 14 jours commencera des la validation du paiement." (source: caracteres Unicode dans le code) | OK mais ambigu : suggere "validation du paiement" alors qu il s agit d activation Stripe, pas de debit |

### E.2 Problemes identifies dans le copy actuel

1. **"Pendant l'essai, tout le monde teste Autopilot"** : ton familier / amateur, devrait etre B2B SaaS pro.
2. **Manque un bloc financier explicite** : aucun "0 EUR aujourd'hui", "Aucun debit", "Carte non debitee" rassurant pre-CTA.
3. **CTA microcopy l.748** : "CB requise a cette etape uniquement" -- jargon utilisateur final.
4. **Bloc 3 etapes l.644** : "vous testez Autopilot pour voir toute la valeur" -- marketing fluffy.
5. **Header step checkout l.980** : "des la validation du paiement" pourrait laisser penser au debit immediat.

### E.3 Promesses sensibles a verifier cote billing/Stripe/API

| Promesse | Verification requise | Risque si non verifiee |
|---|---|---|
| "Aucun debit aujourd'hui" / "0 EUR aujourd'hui" | Stripe checkout-session : trial_period_days >= 14, no setup_intent capture immediate | Si Stripe debite reellement aujourd'hui -> claim fraude/false advertising |
| "Annulable pendant l essai" | API logique resiliation pendant trial active | Si user n a pas de moyen de resilier -> bad faith |
| "Rappel avant la fin de l essai" | Email scheduler J-3/J-1 avant fin trial | Inventer un rappel inexistant = mensonge -- A NE PAS PROMETTRE sans verif |
| "Le plan choisi s applique apres les 14 jours" | API tenant.trial_entitlement_plan -> tenant.plan switch a J+14 | Logic preexistante mais a confirmer cote Stripe webhook + API |
| "Carte demandee pour activer l essai" | Stripe checkout-session avec card collection requise | Match implementation actuelle (CB requise pre-trial) |

**Doctrine PH-19.6** : Ne promettre que les promesses verifiables cote billing/Stripe/API. Ne PAS promettre rappel email avant fin essai sans verification scheduler dedie.

---

## F. 10 PROPOSITIONS COPY (0 EUR aujourd'hui / aucun debit avant J+14)

Chaque proposition contient :
1. Titre court bloc
2. Phrase principale
3. Microcopy sous CTA
4. Variante courte panneau lateral
5. Note UX
6. Risque eventuel

---

### F.1 Option 1 - "Minimal financier" (style Linear/Notion)

1. **Titre bloc** : 0 EUR aujourd'hui
2. **Phrase principale** : Votre carte est demandee pour activer l'essai. Aucun debit avant la fin des 14 jours.
3. **Microcopy sous CTA** : 14 jours sur Autopilot. Annulable a tout moment. Le plan choisi s'applique apres l'essai.
4. **Variante laterale** : 0 EUR aujourd'hui. Essai 14 jours sur Autopilot, puis votre plan.
5. **Note UX** : tres lisible, signal financier en titre, phrase principale ferme et factuelle. Pas de fluff. Rassure sans dramatiser.
6. **Risque** : "Aucun debit avant la fin des 14 jours" -> verifier Stripe trial_period_days = 14 + aucune capture intermediate.

---

### F.2 Option 2 - "Garantie zero debit" (style Stripe/Spotify)

1. **Titre bloc** : Aucun debit aujourd'hui
2. **Phrase principale** : Vous activez l'essai avec votre carte, mais rien n'est preleve avant la fin des 14 jours. Vous pouvez annuler en un clic pendant cette periode.
3. **Microcopy sous CTA** : Essai 14 jours sur Autopilot. A la fin, votre plan choisi prend le relais si vous continuez.
4. **Variante laterale** : Aucun debit aujourd'hui. Essai 14 jours sur Autopilot.
5. **Note UX** : double rassurance (zero debit + annulation un clic). Bon pour CRO B2B SaaS.
6. **Risque** : "annuler en un clic" -> verifier UI resiliation accessible en un clic dans Settings/Billing client (sinon mensonge UX).

---

### F.3 Option 3 - "Garantie sans surprise" (style Datadog/Segment)

1. **Titre bloc** : 0 EUR maintenant. 0 EUR pendant 14 jours.
2. **Phrase principale** : Nous demandons votre carte pour activer Autopilot pendant l'essai, mais aucun montant ne sera preleve avant la fin des 14 jours.
3. **Microcopy sous CTA** : Vous pouvez changer de plan ou annuler a tout moment pendant l'essai.
4. **Variante laterale** : 0 EUR pendant 14 jours. Essai sur Autopilot, puis votre plan.
5. **Note UX** : repetition "0 EUR" double martele l idee. Tres clair pour profil prudent.
6. **Risque** : confirmer absence totale de pre-authorisation captee. Stripe SetupIntent simple est OK.

---

### F.4 Option 4 - "Promesse claire" (style Adobe)

1. **Titre bloc** : Votre carte ne sera pas debitee aujourd'hui
2. **Phrase principale** : Aucun montant n'est preleve avant la fin de votre essai de 14 jours sur Autopilot. A l'issue, si vous continuez, vous passez sur le plan selectionne ici.
3. **Microcopy sous CTA** : Resiliable a tout moment depuis votre espace Facturation.
4. **Variante laterale** : Carte non debitee aujourd'hui. Essai 14 jours sur Autopilot.
5. **Note UX** : phrase complete, formelle, ton entreprise. Bon pour B2B serieux.
6. **Risque** : "depuis votre espace Facturation" -> verifier que l espace existe et la resiliation y est accessible.

---

### F.5 Option 5 - "Sans engagement" (style Netflix/Disney)

1. **Titre bloc** : 14 jours d'essai sur Autopilot. Sans engagement.
2. **Phrase principale** : 0 EUR aujourd'hui. Votre carte est uniquement utilisee pour demarrer l'essai. Aucun debit avant le terme des 14 jours.
3. **Microcopy sous CTA** : Annulez quand vous voulez. Le plan choisi s'applique apres l'essai si vous continuez.
4. **Variante laterale** : 14 jours d'essai. Sans engagement. 0 EUR aujourd'hui.
5. **Note UX** : "sans engagement" est un signal fort attendu en SaaS B2B. "Quand vous voulez" rassure.
6. **Risque** : "sans engagement" implicite -- pas de minimum 12 mois ? Verifier billing config (pas de minCommitment Stripe).

---

### F.6 Option 6 - "Activation, pas paiement" (style Mailchimp)

1. **Titre bloc** : Activation, pas paiement
2. **Phrase principale** : Votre carte sert uniquement a activer l'essai sur Autopilot. Vous ne payez rien aujourd'hui, et rien pendant les 14 jours suivants.
3. **Microcopy sous CTA** : Apres l'essai, votre plan se met en place si vous continuez. Vous pouvez annuler avant la fin de l'essai.
4. **Variante laterale** : Activation aujourd'hui. Paiement uniquement si vous continuez apres 14 jours.
5. **Note UX** : redefinit semantiquement l action "carte demandee = activation, pas paiement". Bon pour reduire la friction perceptuelle.
6. **Risque** : "vous ne payez rien" -> verifier strictement Stripe trial config (pas meme 1 EUR de pre-auth captee).

---

### F.7 Option 7 - "Test complet sans risque" (style Intercom/HubSpot)

1. **Titre bloc** : Testez Autopilot sans risque pendant 14 jours
2. **Phrase principale** : 0 EUR aujourd'hui. Votre carte permet d'activer l'essai mais aucun debit n'a lieu avant la fin de la periode d'essai.
3. **Microcopy sous CTA** : Au terme des 14 jours, votre plan selectionne se met en place. Vous pouvez le modifier ou annuler avant cette date.
4. **Variante laterale** : Autopilot sans risque pendant 14 jours. 0 EUR maintenant.
5. **Note UX** : "sans risque" = signal fort. "permettre" plus doux que "obligatoire". Bon pour profil hesitant.
6. **Risque** : "sans risque" est un superlatif. Verifier qu il n y a aucun cas ou un debit accidentel pourrait arriver (echec annulation, etc.).

---

### F.8 Option 8 - "Engagement reciproque" (style Zendesk/Pipedrive)

1. **Titre bloc** : 0 EUR aujourd'hui. Votre engagement zero, le notre est total.
2. **Phrase principale** : Pour activer Autopilot et vous donner acces a la version la plus complete pendant 14 jours, votre carte est demandee. Aucun montant n'est preleve avant la fin de l'essai.
3. **Microcopy sous CTA** : Apres l'essai, le plan choisi s'applique uniquement si vous decidez de continuer.
4. **Variante laterale** : Zero engagement de votre cote pendant 14 jours.
5. **Note UX** : pose une dynamique "vous testez sans risque, on vous donne le meilleur". Bon pour offre value-first.
6. **Risque** : "notre engagement est total" est subjectif -- ne promet rien d operable. Plus marketing que claim risque.

---

### F.9 Option 9 - "Factuel et clair" (style Stripe/Atlassian)

1. **Titre bloc** : 0 EUR pendant 14 jours
2. **Phrase principale** : Carte demandee a l'activation. Aucun debit avant J+14. A l'issue de l'essai, le plan selectionne devient actif si vous decidez de continuer.
3. **Microcopy sous CTA** : Vous pouvez changer ou annuler votre plan pendant l'essai depuis votre Facturation.
4. **Variante laterale** : 0 EUR pendant 14 jours. Carte demandee a l'activation.
5. **Note UX** : tres factuel, presque legal. Inspire confiance pour profil expert/RH/finance.
6. **Risque** : verifier l UI Facturation et la capacite a changer de plan pendant l essai (preexistant probablement -- a confirmer).

---

### F.10 Option 10 - "Tranquillite" (style Apple One/Shopify)

1. **Titre bloc** : Aujourd'hui, vous ne payez rien
2. **Phrase principale** : L'essai de 14 jours sur Autopilot demarre maintenant. Votre carte est demandee pour l'activation, mais le premier debit n'a lieu qu'apres l'essai, et uniquement si vous decidez de continuer.
3. **Microcopy sous CTA** : Vous pouvez tout annuler ou ajuster votre plan a tout moment pendant l'essai.
4. **Variante laterale** : Aujourd'hui, vous ne payez rien. Essai 14 jours sur Autopilot.
5. **Note UX** : phrase d ouverture directe, ton conversationnel sans etre familier. "tranquillite" implicite. Tres efficace pour decideurs.
6. **Risque** : "premier debit n a lieu qu apres" -- verifier que c est vrai cote Stripe (pas de setup_intent captee). "uniquement si vous decidez de continuer" -- confirmer auto-bascule trial -> plan.

---

## G. RECOMMANDATION CE : TOP 3

### G.1 Top 3 ranked

| Rang | Option | Pourquoi |
|---|---|---|
| 1er | **F.9 (Factuel et clair, style Stripe/Atlassian)** | Wording le plus pro/B2B, factuel, sans superlatif risque. Aligne avec le ton tech-serieux Stripe/Atlassian. Risque verification minimal. |
| 2eme | **F.1 (Minimal financier, style Linear/Notion)** | Signal financier "0 EUR" en titre, phrase ferme. Tres efficace, peu de risque (juste verif Stripe trial_period_days). Style SaaS moderne. |
| 3eme | **F.3 (Garantie sans surprise, style Datadog/Segment)** | Repetition "0 EUR" double, clair pour profil prudent. Bon hybride entre F.1 et F.4. |

### G.2 Pourquoi PAS les autres

- F.2 / F.5 / F.6 / F.10 : promesses "annuler en un clic" / "sans engagement" / "premier debit apres" -- verifications operationnelles plus lourdes a faire avant promesse.
- F.4 : "depuis votre espace Facturation" -- a verifier preexistant.
- F.7 : "sans risque" superlatif -- a eviter en B2B serieux (sans risque = aucun moyen de perdre, claim difficile).
- F.8 : "notre engagement est total" -- subjectif et faible.

### G.3 Recommandation finale CE

**Option F.9 (Factuel et clair)** + patch CGU option D (persist + encart "CGU acceptees" visible).

Wording integre proposed dans le code source (apres GO Ludovic) :

```tsx
{/* Bloc 0 EUR detonnant - PH-SAAS-T8.12AS.19.6 */}
<div className="mb-6 rounded-xl border-2 border-green-500/40 bg-green-500/10 px-5 py-4 text-center" data-testid="register-zero-debit-block">
  <p className="text-base font-bold text-white flex items-center justify-center gap-2">
    <Lock className="h-4 w-4 text-green-400" />
    0 EUR pendant 14 jours
  </p>
  <p className="mt-2 text-sm text-gray-200 leading-relaxed">
    Carte demandee a l&apos;activation. Aucun debit avant J+14. A l&apos;issue de l&apos;essai, le plan selectionne devient actif si vous decidez de continuer.
  </p>
</div>
```

Microcopy sous CTA "Confirmer ce plan et activer l'essai 14 jours" (remplacement l.748) :
```
Vous pouvez changer ou annuler votre plan pendant l'essai depuis votre Facturation.
```

Variante laterale ReassurancePanel (remplacement l.597) :
```
0 EUR pendant 14 jours. Carte demandee a l'activation.
```

Header step plan sous-titre (remplacement l.663) :
```
14 jours sur Autopilot. Aucun debit avant le J+14.
```

Suppression de l encart "Pendant l'essai, tout le monde teste Autopilot" (l.664-668) :
- Remplacer par le bloc 0 EUR ci-dessus.
- Conserver l info "essai sur Autopilot quel que soit le plan" en phrase normale plus haut ou sous le bloc 0 EUR.

---

## H. VERDICT FINAL

NO GO BUILD - ATTENTE CHOIX COPY + GO PATCH

| Indicateur | Valeur |
|---|---|
| Phase | PH-SAAS-T8.12AS.19.6-REGISTER-QA-CGU-STATE-AND-COPY-PROPOSALS |
| Type | Audit source + propositions only |
| Bug CGU cause racine | acceptCgu non persiste dans sessionStorage + checkbox UI uniquement sur step user |
| Patch CGU propose | Option D = persist sessionStorage + encart visuel non-bloquant sur step plan (NON applique) |
| Copy actuel problematique | "tout le monde teste Autopilot" (familier) + manque bloc 0 EUR financier rassurant |
| Top 3 propositions copy | F.9 (1er - factuel Stripe/Atlassian), F.1 (2eme - minimal Linear/Notion), F.3 (3eme - garantie Datadog) |
| Recommandation CE | F.9 + patch CGU option D |
| Promesses sensibles a verifier | Stripe trial_period_days=14, absence setup_intent captee, UI annulation/changement plan pendant trial dans Facturation |
| NO BUILD | OK |
| NO DOCKER PUSH | OK |
| NO kubectl | OK |
| NO commit | OK |
| NO push | OK |
| NO patch applique | OK |
| Runtime Client DEV | v3.5.203-register-autopilot-trial-copy-dev (preserve depuis PH-19.5 apply) |
| Runtime PROD | inchange |
| Rapport ASCII strict + no BOM | a SCP vers keybuzz-infra/docs |
| Linear ticket close | aucun |
| Clarity activation | non activee preserve |

### Prochaine action utilisateur

Choisir parmi :
- **GO PATCH F.9 CGU + COPY PH-SAAS-T8.12AS.19.6** (recommandation CE)
- **GO PATCH F.1 CGU + COPY PH-SAAS-T8.12AS.19.6**
- **GO PATCH F.3 CGU + COPY PH-SAAS-T8.12AS.19.6**
- **GO PATCH F.X CGU + COPY PH-SAAS-T8.12AS.19.6** (autre option)
- **AUTRE FORMULATION** (Ludovic propose un mix ou un wording custom)
- **NO GO** (replanifier ou modifier le scope)

STOP en attente choix Ludovic.
