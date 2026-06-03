1. Story : Création initiale de catalogue (initial_catalog_creation.feature)
Gherkin
# language: fr
Fonctionnalité: Création initiale de catalogue avec IDs séquentiels isolés
  En tant que Gestionnaire de Tarification
  Je veux initialiser conjointement un conteneur master et son premier brouillon
  Afin de démarrer le cycle de vie d'un catalogue avec des clés uniques générées par la base de données

  Plan du Scénario: Initialisation conjointe du catalogue maître et de sa V1 à partir des séquences
    Quand je demande la création d'un catalogue de type "<type_catalogue>"
    Alors le système consomme la séquence "SEQ_CATALOG_ID" et génère l'ID catalogue <id_catalogue>
    Et le système consomme la séquence "SEQ_CATALOG_VERSION_ID" et génère l'ID version <id_version>
    Et le catalogue créé porte l'ID <id_catalogue> et le type "<type_catalogue>"
    Et la version créée porte l'ID <id_version>, est rattachée au catalogue <id_catalogue> et possède le statut "DRAFT"
    Et le numéro de version affiché est "1.0"

    Exemples:
      | type_catalogue | id_catalogue | id_version |
      | Cash           | 1001         | 50001      |
      | Cards          | 1002         | 50002      |
      | Securities     | 1003         | 50003      |
2. Story : Gestion de l'espace de travail (Multi-Drafts) (multi_draft_workspace.feature)
Gherkin
# language: fr
Fonctionnalité: Gestion de l'espace de travail en Multi-Drafts séquentiels
  En tant que Gestionnaire de Tarification
  Je veux instancier plusieurs brouillons en parallèle pour un même catalogue
  Afin de travailler sur des configurations indépendantes identifiables par leur propre URL technique

  Contexte:
    Étant donné un catalogue actif enregistré avec l'ID séquentiel 2045
    Et que ce catalogue possède une version de référence au statut "ACTIF" ayant l'ID version 75001

  Scénario: Création de plusieurs brouillons en parallèle à partir de la version de référence active
    Quand je demande la création d'un premier brouillon pour le catalogue 2045
    Alors la séquence "SEQ_CATALOG_VERSION_ID" s'incrémente et retourne l'ID version 75002
    Quand je demande la création d'un second brouillon pour le même catalogue 2045
    Alors la séquence "SEQ_CATALOG_VERSION_ID" s'incrémente à nouveau et retourne l'ID version 75003
    Et les versions 75002 et 75003 sont toutes deux rattachées au catalogue 2045 au statut "DRAFT"
    Et elles héritent indépendamment des données de la version active 75001

  Scénario: Isolation et non-impaction des modifications entre les versions drafts d'un même catalogue
    Étant donné les versions drafts 75002 et 75003 rattachées au catalogue 2045
    Quand je modifie le contenu de la version via l'identifiant technique 75002 dans l'URL
    Et que j'ajoute le segment de clientèle "External Financial Institution"
    Alors le segment est associé uniquement à la version 75002
    Et le contenu de la version 75003 reste inchangé et préservé
3. Story : Cycle de vie du Workflow (Soumission & Validation) (catalog_workflow_lifecycle.feature)
Gherkin
# language: fr
Fonctionnalité: Cycle de vie du Workflow et bascule d'activation atomique
  En tant que Valideur Métier
  Je veux approuver une version en attente pour basculer instantanément l'état du catalogue
  Afin d'assurer la continuité et l'unicité de la tarification en vigueur

  Scénario: Soumission d'un draft spécifique vers l'attente de validation
    Étant donné un catalogue 3088 contenant une version 81005 au statut "DRAFT"
    Quand je soumets la version 81005 pour validation
    Alors le statut de la version 81005 passe à "PENDING_VALIDATION"
    Et le catalogue maître 3088 reste accessible sans modification globale

  Scénario: Validation d'une version en attente et archivage automatique de l'ancienne version active
    Étant donné le catalogue 3088 possédant l'historique de versions suivant :
      | Version ID | Statut             |
      | 81001      | ACTIF              |
      | 81005      | PENDING_VALIDATION |
    Quand j'approuve la validation de la version 81005
    Alors la transaction de validation s'exécute de manière atomique en base de données
    Et le statut de la version 81005 passe à "ACTIF"
    Et le statut de l'ancienne version 81001 bascule immédiatement à "ARCHIVED"
    Et une vérification du catalogue 3088 confirme qu'il ne contient qu'une seule et unique version au statut "ACTIF"
4. Story : Clôture et Rôles de Sécurité (catalog_security_rules.feature)
Gherkin
# language: fr
Fonctionnalité: Sécurisation des statuts et nettoyage des données de version
  En tant que Système d'Intégrité Référentielle
  Je veux interdire les suppressions illégitimes et purger les données associées en cascade
  Afin de maintenir une base de données propre et un historique auditable

  Scénario: Suppression d'une version DRAFT et nettoyage en cascade des segments associés
    Étant donné un catalogue 4012 contenant une version 92004 au statut "DRAFT"
    Et que des segments de données sont physiquement stockés pour cette version 92004
    Quand je supprime définitivement la version 92004
    Alors l'enregistrement de la version 92004 est retiré de la table des versions
    Et tous les segments liés à l'ID version 92004 sont supprimés en cascade par l'ORM

  Plan du Scénario: Interdiction de modification et de suppression sur les versions immuables
    Étant donné un catalogue 4012 contenant une version <id_version> au statut "<statut_protege>"
    Quand je tente d'exécuter une modification sur la version <id_version>
    Ou que je tente d'envoyer une requête de suppression pour la version <id_version>
    Alors le système bloque l'opération et lève une exception de sécurité métier
    Et l'état de la version <id_version> ainsi que ses données restent strictement inchangés

    Exemples:
      | id_version | statut_protege |
      | 92001      | ACTIF          |
      | 91002      | ARCHIVED       |




5. Story : Gestion de la portée des Entités Juridiques (version_entities.feature)
Gherkin
# language: fr
Fonctionnalité: Gestion du périmètre des Entités Juridiques sur la Version
  En tant que Gestionnaire de Tarification
  Je veux associer ou retirer des entités géographiques à une version spécifique de catalogue
  Afin de définir précisément quelles filiales appliqueront ces grilles tarifaires

  Contexte:
    Étant donné un catalogue maître ayant l'ID 1005

  Scénario: Ajout réussi d'entités juridiques sur une version au statut DRAFT
    Étant donné que le catalogue 1005 possède une version 50021 au statut "DRAFT"
    Quand j'associe les entités suivantes à la version 50021 :
      | Entity Code | Entity Name      |
      | 14910       | CA-CIB (LONDON)  |
      | 15203       | CA-CIB (INDIA)   |
    Alors la version 50021 enregistre ces 2 entités dans son périmètre de validité
    Et la consultation de la version 50021 affiche un compteur d'entités égal à 2

  Scénario: Rejet de modification des entités sur une version protégée
    Étant donné que le catalogue 1005 possède une version 50010 au statut "ACTIF"
    Quand je tente d'ajouter l'entité "14910" à la version 50010
    Alors le système refuse l'opération
    Et l'erreur "Règle de sécurité : Interdiction de modifier une version au statut ACTIF" est levée
6. Story : Gestion des Segments de Clientèle (version_segments.feature)
Gherkin
# language: fr
Fonctionnalité: Configuration des Segments de clientèle et des listes d'exceptions
  En tant que Gestionnaire de Tarification
  Je veux configurer les segments cibles sur un brouillon de version
  Afin d'isoler les règles d'application des types de commissions (BEN, SHA, OUR)

  Contexte:
    Étant donné un catalogue maître ayant l'ID 2012

  Scénario: Configuration d'un segment avec indicateur d'exception sur un brouillon
    Étant donné que le catalogue 2012 possède une version 64002 au statut "DRAFT"
    Quand j'ajoute le segment "External Financial Institution" à la version 64002
    Et que je configure l'option "Exceptional List" à "No"
    Alors le segment est rattaché à la version séquentielle 64002
    Et ce segment n'affecte aucun autre draft ou version du catalogue 2012

  Scénario: Retrait d'un segment et nettoyage associé
    Étant donné que le catalogue 2012 possède une version 64002 contenant le segment "Corporate"
    Quand je supprime le segment "Corporate" de cette version 64002
    Alors l'association est immédiatement rompue pour cette version uniquement
7. Story : Catalogue des Produits, Services et Tarification (version_products_pricing.feature)
Gherkin
# language: fr
Fonctionnalité: Gestion des Produits, Services et structures de prix par Version
  En tant que Gestionnaire de Tarification
  Je veux enrichir et tarifer les services financiers au sein d'une version isolée
  Afin de modéliser les frais par paliers (Volume Range) et d'affecter les codes comptables applicatifs

  Contexte:
    Étant donné un catalogue maître ayant l'ID 3099
    Et une version draft générée avec l'ID séquentiel 78005 au statut "DRAFT"

  Scénario: Ajout et configuration complète d'un produit financier dans un brouillon
    Quand j'ajoute un produit à la version 78005 avec les métadonnées suivantes :
      | Unique Product ID | Product Version ID | Family               | Sub Family           | Product                        | Billing Code |
      | 23443             | 33362              | Liquidity management | Domestic Cash Pooling | Interest set off Account setup | 090010010    |
    Et que je configure les "Billing Options" du produit sur la version 78005 :
      | Kind of fees   | Billing Mode | Calculation Mode       | Price Unit       | Price Type   | Price | Currency |
      | Recurring fees | Deferred     | Number of transactions | Per transaction  | Volume Range | 1.00  | EUR      |
    Et que je renseigne les codes applicatifs d'imputation technique :
      | Accounting Code | AFP Code | CRT Code | GPP |
      | NOTAPP          | NOTAPP   | NOTAPP   | 1   |
    Alors le produit est indexé de manière unique sous l'ID produit 23443 pour la seule version 78005
    Et le prix unitaire par palier à "1.00" EUR est encapsulé dans cette version

  Scénario: Configuration des indicateurs de type de commission (Commission Type) et des preuves
    Étant donné le produit 23443 déjà présent dans la version draft 78005
    Quand je configure les indicateurs de flags métiers :
      | Repair Corporate Flag | Repair FI Commercial Payment | Correspondent Flag | Change Flag |
      | No                    | No                          | No                 | No          |
    Et que je désactive les options de la section "Billing Proof" (Repair Fees, OUR Commission, Claims)
    Alors la structure comportementale du produit est sauvegardée avec succès dans la version 78005
    Et les versions d'historique "ACTIF" ou "ARCHIVED" liées au catalogue 3099 restent inchangées

  Plan du Scénario: Blocage sécurisé des modifications tarifaires sur l'offre en vigueur
    Étant donné que le catalogue 3099 possède une version de référence <id_version> au statut "<statut_bloquant>"
    Quand je tente d'altérer la configuration tarifaire d'un produit au sein de la version <id_version>
    Alors le système lève une exception de violation de contrainte métier
    Et aucun impact ou régénération de prix n'est toléré sur la version <id_version>

    Exemples:
      | id_version | statut_bloquant |
      | 78001      | ACTIF           |
      | 77002      | ARCHIVED        |	  
