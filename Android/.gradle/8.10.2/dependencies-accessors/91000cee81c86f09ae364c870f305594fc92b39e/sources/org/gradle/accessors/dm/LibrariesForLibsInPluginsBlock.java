package org.gradle.accessors.dm;

import org.gradle.api.NonNullApi;
import org.gradle.api.artifacts.MinimalExternalModuleDependency;
import org.gradle.plugin.use.PluginDependency;
import org.gradle.api.artifacts.ExternalModuleDependencyBundle;
import org.gradle.api.artifacts.MutableVersionConstraint;
import org.gradle.api.provider.Provider;
import org.gradle.api.model.ObjectFactory;
import org.gradle.api.provider.ProviderFactory;
import org.gradle.api.internal.catalog.AbstractExternalDependencyFactory;
import org.gradle.api.internal.catalog.DefaultVersionCatalog;
import java.util.Map;
import org.gradle.api.internal.attributes.ImmutableAttributesFactory;
import org.gradle.api.internal.artifacts.dsl.CapabilityNotationParser;
import javax.inject.Inject;

/**
 * A catalog of dependencies accessible via the {@code libs} extension.
 */
@NonNullApi
public class LibrariesForLibsInPluginsBlock extends AbstractExternalDependencyFactory {

    private final AbstractExternalDependencyFactory owner = this;
    private final AndroidxLibraryAccessors laccForAndroidxLibraryAccessors = new AndroidxLibraryAccessors(owner);
    private final CoilLibraryAccessors laccForCoilLibraryAccessors = new CoilLibraryAccessors(owner);
    private final FirebaseLibraryAccessors laccForFirebaseLibraryAccessors = new FirebaseLibraryAccessors(owner);
    private final KotlinLibraryAccessors laccForKotlinLibraryAccessors = new KotlinLibraryAccessors(owner);
    private final KotlinxLibraryAccessors laccForKotlinxLibraryAccessors = new KotlinxLibraryAccessors(owner);
    private final VersionAccessors vaccForVersionAccessors = new VersionAccessors(providers, config);
    private final BundleAccessors baccForBundleAccessors = new BundleAccessors(objects, providers, config, attributesFactory, capabilityNotationParser);
    private final PluginAccessors paccForPluginAccessors = new PluginAccessors(providers, config);

    @Inject
    public LibrariesForLibsInPluginsBlock(DefaultVersionCatalog config, ProviderFactory providers, ObjectFactory objects, ImmutableAttributesFactory attributesFactory, CapabilityNotationParser capabilityNotationParser) {
        super(config, providers, objects, attributesFactory, capabilityNotationParser);
    }

    /**
     * Group of libraries at <b>androidx</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public AndroidxLibraryAccessors getAndroidx() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return laccForAndroidxLibraryAccessors;
    }

    /**
     * Group of libraries at <b>coil</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public CoilLibraryAccessors getCoil() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return laccForCoilLibraryAccessors;
    }

    /**
     * Group of libraries at <b>firebase</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public FirebaseLibraryAccessors getFirebase() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return laccForFirebaseLibraryAccessors;
    }

    /**
     * Group of libraries at <b>kotlin</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public KotlinLibraryAccessors getKotlin() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return laccForKotlinLibraryAccessors;
    }

    /**
     * Group of libraries at <b>kotlinx</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public KotlinxLibraryAccessors getKotlinx() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return laccForKotlinxLibraryAccessors;
    }

    /**
     * Group of versions at <b>versions</b>
     */
    public VersionAccessors getVersions() {
        return vaccForVersionAccessors;
    }

    /**
     * Group of bundles at <b>bundles</b>
     *
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public BundleAccessors getBundles() {
        org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
        return baccForBundleAccessors;
    }

    /**
     * Group of plugins at <b>plugins</b>
     */
    public PluginAccessors getPlugins() {
        return paccForPluginAccessors;
    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxLibraryAccessors extends SubDependencyFactory {
        private final AndroidxActivityLibraryAccessors laccForAndroidxActivityLibraryAccessors = new AndroidxActivityLibraryAccessors(owner);
        private final AndroidxAppcompatLibraryAccessors laccForAndroidxAppcompatLibraryAccessors = new AndroidxAppcompatLibraryAccessors(owner);
        private final AndroidxComposeLibraryAccessors laccForAndroidxComposeLibraryAccessors = new AndroidxComposeLibraryAccessors(owner);
        private final AndroidxCoreLibraryAccessors laccForAndroidxCoreLibraryAccessors = new AndroidxCoreLibraryAccessors(owner);
        private final AndroidxLifecycleLibraryAccessors laccForAndroidxLifecycleLibraryAccessors = new AndroidxLifecycleLibraryAccessors(owner);
        private final AndroidxNavigationLibraryAccessors laccForAndroidxNavigationLibraryAccessors = new AndroidxNavigationLibraryAccessors(owner);

        public AndroidxLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Group of libraries at <b>androidx.activity</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxActivityLibraryAccessors getActivity() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxActivityLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.appcompat</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxAppcompatLibraryAccessors getAppcompat() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxAppcompatLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.compose</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeLibraryAccessors getCompose() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.core</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxCoreLibraryAccessors getCore() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxCoreLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.lifecycle</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxLifecycleLibraryAccessors getLifecycle() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxLifecycleLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.navigation</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxNavigationLibraryAccessors getNavigation() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxNavigationLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxActivityLibraryAccessors extends SubDependencyFactory {

        public AndroidxActivityLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>compose</b> with <b>androidx.activity:activity-compose</b> coordinates and
         * with version reference <b>androidx.activity</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getCompose() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.activity.compose");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxAppcompatLibraryAccessors extends SubDependencyFactory implements DependencyNotationSupplier {

        public AndroidxAppcompatLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>appcompat</b> with <b>androidx.appcompat:appcompat</b> coordinates and
         * with version reference <b>androidx.appcompat</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> asProvider() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.appcompat");
        }

        /**
         * Dependency provider for <b>resources</b> with <b>androidx.appcompat:appcompat-resources</b> coordinates and
         * with version reference <b>androidx.appcompat</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getResources() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.appcompat.resources");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeLibraryAccessors extends SubDependencyFactory {
        private final AndroidxComposeMaterialLibraryAccessors laccForAndroidxComposeMaterialLibraryAccessors = new AndroidxComposeMaterialLibraryAccessors(owner);
        private final AndroidxComposeMaterial3LibraryAccessors laccForAndroidxComposeMaterial3LibraryAccessors = new AndroidxComposeMaterial3LibraryAccessors(owner);
        private final AndroidxComposeUiLibraryAccessors laccForAndroidxComposeUiLibraryAccessors = new AndroidxComposeUiLibraryAccessors(owner);

        public AndroidxComposeLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>animation</b> with <b>androidx.compose.animation:animation</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getAnimation() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.animation");
        }

        /**
         * Dependency provider for <b>bom</b> with <b>androidx.compose:compose-bom</b> coordinates and
         * with version reference <b>androidx.compose.bom</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getBom() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.bom");
        }

        /**
         * Dependency provider for <b>foundation</b> with <b>androidx.compose.foundation:foundation</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getFoundation() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.foundation");
        }

        /**
         * Dependency provider for <b>runtime</b> with <b>androidx.compose.runtime:runtime</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getRuntime() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.runtime");
        }

        /**
         * Group of libraries at <b>androidx.compose.material</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeMaterialLibraryAccessors getMaterial() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeMaterialLibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.compose.material3</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeMaterial3LibraryAccessors getMaterial3() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeMaterial3LibraryAccessors;
        }

        /**
         * Group of libraries at <b>androidx.compose.ui</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeUiLibraryAccessors getUi() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeUiLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeMaterialLibraryAccessors extends SubDependencyFactory implements DependencyNotationSupplier {
        private final AndroidxComposeMaterialIconsLibraryAccessors laccForAndroidxComposeMaterialIconsLibraryAccessors = new AndroidxComposeMaterialIconsLibraryAccessors(owner);

        public AndroidxComposeMaterialLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>material</b> with <b>androidx.compose.material:material</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> asProvider() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.material");
        }

        /**
         * Group of libraries at <b>androidx.compose.material.icons</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeMaterialIconsLibraryAccessors getIcons() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeMaterialIconsLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeMaterialIconsLibraryAccessors extends SubDependencyFactory {

        public AndroidxComposeMaterialIconsLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>extended</b> with <b>androidx.compose.material:material-icons-extended</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getExtended() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.material.icons.extended");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeMaterial3LibraryAccessors extends SubDependencyFactory implements DependencyNotationSupplier {

        public AndroidxComposeMaterial3LibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>material3</b> with <b>androidx.compose.material3:material3</b> coordinates and
         * with version <b>1.4.0-alpha04</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> asProvider() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.material3");
        }

        /**
         * Dependency provider for <b>adaptive</b> with <b>androidx.compose.material3.adaptive:adaptive</b> coordinates and
         * with version reference <b>androidx.material3.adaptive</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getAdaptive() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.material3.adaptive");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeUiLibraryAccessors extends SubDependencyFactory implements DependencyNotationSupplier {
        private final AndroidxComposeUiTestLibraryAccessors laccForAndroidxComposeUiTestLibraryAccessors = new AndroidxComposeUiTestLibraryAccessors(owner);

        public AndroidxComposeUiLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>ui</b> with <b>androidx.compose.ui:ui</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> asProvider() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.ui");
        }

        /**
         * Dependency provider for <b>tooling</b> with <b>androidx.compose.ui:ui-tooling</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getTooling() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.ui.tooling");
        }

        /**
         * Group of libraries at <b>androidx.compose.ui.test</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public AndroidxComposeUiTestLibraryAccessors getTest() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForAndroidxComposeUiTestLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxComposeUiTestLibraryAccessors extends SubDependencyFactory implements DependencyNotationSupplier {

        public AndroidxComposeUiTestLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>test</b> with <b>androidx.compose.ui:ui-test</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> asProvider() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.ui.test");
        }

        /**
         * Dependency provider for <b>junit4</b> with <b>androidx.compose.ui:ui-test-junit4</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getJunit4() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.ui.test.junit4");
        }

        /**
         * Dependency provider for <b>manifest</b> with <b>androidx.compose.ui:ui-test-manifest</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getManifest() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.compose.ui.test.manifest");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxCoreLibraryAccessors extends SubDependencyFactory {

        public AndroidxCoreLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>ktx</b> with <b>androidx.core:core-ktx</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getKtx() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.core.ktx");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxLifecycleLibraryAccessors extends SubDependencyFactory {

        public AndroidxLifecycleLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>process</b> with <b>androidx.lifecycle:lifecycle-process</b> coordinates and
         * with version reference <b>androidx.lifecycle.process</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getProcess() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.lifecycle.process");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class AndroidxNavigationLibraryAccessors extends SubDependencyFactory {

        public AndroidxNavigationLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>compose</b> with <b>androidx.navigation:navigation-compose</b> coordinates and
         * with version reference <b>androidx.navigation</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getCompose() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("androidx.navigation.compose");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class CoilLibraryAccessors extends SubDependencyFactory {
        private final CoilNetworkLibraryAccessors laccForCoilNetworkLibraryAccessors = new CoilNetworkLibraryAccessors(owner);

        public CoilLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>compose</b> with <b>io.coil-kt.coil3:coil-compose</b> coordinates and
         * with version reference <b>coil</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getCompose() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("coil.compose");
        }

        /**
         * Dependency provider for <b>svg</b> with <b>io.coil-kt.coil3:coil-svg</b> coordinates and
         * with version reference <b>coil</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getSvg() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("coil.svg");
        }

        /**
         * Group of libraries at <b>coil.network</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public CoilNetworkLibraryAccessors getNetwork() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForCoilNetworkLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class CoilNetworkLibraryAccessors extends SubDependencyFactory {

        public CoilNetworkLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>okhttp</b> with <b>io.coil-kt.coil3:coil-network-okhttp</b> coordinates and
         * with version reference <b>coil</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getOkhttp() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("coil.network.okhttp");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class FirebaseLibraryAccessors extends SubDependencyFactory {

        public FirebaseLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>bom</b> with <b>com.google.firebase:firebase-bom</b> coordinates and
         * with version reference <b>firebase</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getBom() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("firebase.bom");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class KotlinLibraryAccessors extends SubDependencyFactory {

        public KotlinLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>bom</b> with <b>org.jetbrains.kotlin:kotlin-bom</b> coordinates and
         * with version reference <b>kotlin</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getBom() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("kotlin.bom");
        }

        /**
         * Dependency provider for <b>reflect</b> with <b>org.jetbrains.kotlin:kotlin-reflect</b> coordinates and
         * with <b>no version specified</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getReflect() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("kotlin.reflect");
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class KotlinxLibraryAccessors extends SubDependencyFactory {
        private final KotlinxCoroutinesLibraryAccessors laccForKotlinxCoroutinesLibraryAccessors = new KotlinxCoroutinesLibraryAccessors(owner);

        public KotlinxLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Group of libraries at <b>kotlinx.coroutines</b>
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public KotlinxCoroutinesLibraryAccessors getCoroutines() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return laccForKotlinxCoroutinesLibraryAccessors;
        }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class KotlinxCoroutinesLibraryAccessors extends SubDependencyFactory {

        public KotlinxCoroutinesLibraryAccessors(AbstractExternalDependencyFactory owner) { super(owner); }

        /**
         * Dependency provider for <b>android</b> with <b>org.jetbrains.kotlinx:kotlinx-coroutines-android</b> coordinates and
         * with version reference <b>kotlin.coroutines</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getAndroid() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("kotlinx.coroutines.android");
        }

        /**
         * Dependency provider for <b>core</b> with <b>org.jetbrains.kotlinx:kotlinx-coroutines-core</b> coordinates and
         * with version reference <b>kotlin.coroutines</b>
         * <p>
         * This dependency was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         *
         * @deprecated Will be removed in Gradle 9.0.
         */
        @Deprecated
        public Provider<MinimalExternalModuleDependency> getCore() {
            org.gradle.internal.deprecation.DeprecationLogger.deprecateBehaviour("Accessing libraries or bundles from version catalogs in the plugins block.").withAdvice("Only use versions or plugins from catalogs in the plugins block.").willBeRemovedInGradle9().withUpgradeGuideSection(8, "kotlin_dsl_deprecated_catalogs_plugins_block").nagUser();
            return create("kotlinx.coroutines.core");
        }

    }

    public static class VersionAccessors extends VersionFactory  {

        private final AndroidVersionAccessors vaccForAndroidVersionAccessors = new AndroidVersionAccessors(providers, config);
        private final AndroidxVersionAccessors vaccForAndroidxVersionAccessors = new AndroidxVersionAccessors(providers, config);
        private final KotlinVersionAccessors vaccForKotlinVersionAccessors = new KotlinVersionAccessors(providers, config);
        public VersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>coil</b> with value <b>3.0.4</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getCoil() { return getVersion("coil"); }

        /**
         * Version alias <b>firebase</b> with value <b>33.8.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getFirebase() { return getVersion("firebase"); }

        /**
         * Version alias <b>jvm</b> with value <b>17</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getJvm() { return getVersion("jvm"); }

        /**
         * Group of versions at <b>versions.android</b>
         */
        public AndroidVersionAccessors getAndroid() {
            return vaccForAndroidVersionAccessors;
        }

        /**
         * Group of versions at <b>versions.androidx</b>
         */
        public AndroidxVersionAccessors getAndroidx() {
            return vaccForAndroidxVersionAccessors;
        }

        /**
         * Group of versions at <b>versions.kotlin</b>
         */
        public KotlinVersionAccessors getKotlin() {
            return vaccForKotlinVersionAccessors;
        }

    }

    public static class AndroidVersionAccessors extends VersionFactory  {

        private final AndroidGradleVersionAccessors vaccForAndroidGradleVersionAccessors = new AndroidGradleVersionAccessors(providers, config);
        private final AndroidSdkVersionAccessors vaccForAndroidSdkVersionAccessors = new AndroidSdkVersionAccessors(providers, config);
        public AndroidVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Group of versions at <b>versions.android.gradle</b>
         */
        public AndroidGradleVersionAccessors getGradle() {
            return vaccForAndroidGradleVersionAccessors;
        }

        /**
         * Group of versions at <b>versions.android.sdk</b>
         */
        public AndroidSdkVersionAccessors getSdk() {
            return vaccForAndroidSdkVersionAccessors;
        }

    }

    public static class AndroidGradleVersionAccessors extends VersionFactory  {

        public AndroidGradleVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>android.gradle.plugin</b> with value <b>8.7.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getPlugin() { return getVersion("android.gradle.plugin"); }

    }

    public static class AndroidSdkVersionAccessors extends VersionFactory  {

        public AndroidSdkVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>android.sdk.compile</b> with value <b>35</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getCompile() { return getVersion("android.sdk.compile"); }

        /**
         * Version alias <b>android.sdk.min</b> with value <b>29</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getMin() { return getVersion("android.sdk.min"); }

    }

    public static class AndroidxVersionAccessors extends VersionFactory  {

        private final AndroidxComposeVersionAccessors vaccForAndroidxComposeVersionAccessors = new AndroidxComposeVersionAccessors(providers, config);
        private final AndroidxLifecycleVersionAccessors vaccForAndroidxLifecycleVersionAccessors = new AndroidxLifecycleVersionAccessors(providers, config);
        private final AndroidxMaterial3VersionAccessors vaccForAndroidxMaterial3VersionAccessors = new AndroidxMaterial3VersionAccessors(providers, config);
        public AndroidxVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>androidx.activity</b> with value <b>1.9.3</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getActivity() { return getVersion("androidx.activity"); }

        /**
         * Version alias <b>androidx.appcompat</b> with value <b>1.7.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getAppcompat() { return getVersion("androidx.appcompat"); }

        /**
         * Version alias <b>androidx.navigation</b> with value <b>2.8.5</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getNavigation() { return getVersion("androidx.navigation"); }

        /**
         * Group of versions at <b>versions.androidx.compose</b>
         */
        public AndroidxComposeVersionAccessors getCompose() {
            return vaccForAndroidxComposeVersionAccessors;
        }

        /**
         * Group of versions at <b>versions.androidx.lifecycle</b>
         */
        public AndroidxLifecycleVersionAccessors getLifecycle() {
            return vaccForAndroidxLifecycleVersionAccessors;
        }

        /**
         * Group of versions at <b>versions.androidx.material3</b>
         */
        public AndroidxMaterial3VersionAccessors getMaterial3() {
            return vaccForAndroidxMaterial3VersionAccessors;
        }

    }

    public static class AndroidxComposeVersionAccessors extends VersionFactory  {

        public AndroidxComposeVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>androidx.compose.bom</b> with value <b>2024.12.01</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getBom() { return getVersion("androidx.compose.bom"); }

    }

    public static class AndroidxLifecycleVersionAccessors extends VersionFactory  {

        public AndroidxLifecycleVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>androidx.lifecycle.process</b> with value <b>2.8.7</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getProcess() { return getVersion("androidx.lifecycle.process"); }

    }

    public static class AndroidxMaterial3VersionAccessors extends VersionFactory  {

        public AndroidxMaterial3VersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>androidx.material3.adaptive</b> with value <b>1.0.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getAdaptive() { return getVersion("androidx.material3.adaptive"); }

    }

    public static class KotlinVersionAccessors extends VersionFactory  implements VersionNotationSupplier {

        public KotlinVersionAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Version alias <b>kotlin</b> with value <b>2.0.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> asProvider() { return getVersion("kotlin"); }

        /**
         * Version alias <b>kotlin.coroutines</b> with value <b>1.9.0</b>
         * <p>
         * If the version is a rich version and cannot be represented as a
         * single version string, an empty string is returned.
         * <p>
         * This version was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<String> getCoroutines() { return getVersion("kotlin.coroutines"); }

    }

    /**
     * @deprecated Will be removed in Gradle 9.0.
     */
    @Deprecated
    public static class BundleAccessors extends BundleFactory {

        public BundleAccessors(ObjectFactory objects, ProviderFactory providers, DefaultVersionCatalog config, ImmutableAttributesFactory attributesFactory, CapabilityNotationParser capabilityNotationParser) { super(objects, providers, config, attributesFactory, capabilityNotationParser); }

    }

    public static class PluginAccessors extends PluginFactory {
        private final AndroidPluginAccessors paccForAndroidPluginAccessors = new AndroidPluginAccessors(providers, config);
        private final KotlinPluginAccessors paccForKotlinPluginAccessors = new KotlinPluginAccessors(providers, config);

        public PluginAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Group of plugins at <b>plugins.android</b>
         */
        public AndroidPluginAccessors getAndroid() {
            return paccForAndroidPluginAccessors;
        }

        /**
         * Group of plugins at <b>plugins.kotlin</b>
         */
        public KotlinPluginAccessors getKotlin() {
            return paccForKotlinPluginAccessors;
        }

    }

    public static class AndroidPluginAccessors extends PluginFactory {

        public AndroidPluginAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Plugin provider for <b>android.application</b> with plugin id <b>com.android.application</b> and
         * with version reference <b>android.gradle.plugin</b>
         * <p>
         * This plugin was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<PluginDependency> getApplication() { return createPlugin("android.application"); }

        /**
         * Plugin provider for <b>android.library</b> with plugin id <b>com.android.library</b> and
         * with version reference <b>android.gradle.plugin</b>
         * <p>
         * This plugin was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<PluginDependency> getLibrary() { return createPlugin("android.library"); }

    }

    public static class KotlinPluginAccessors extends PluginFactory {

        public KotlinPluginAccessors(ProviderFactory providers, DefaultVersionCatalog config) { super(providers, config); }

        /**
         * Plugin provider for <b>kotlin.android</b> with plugin id <b>org.jetbrains.kotlin.android</b> and
         * with version reference <b>kotlin</b>
         * <p>
         * This plugin was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<PluginDependency> getAndroid() { return createPlugin("kotlin.android"); }

        /**
         * Plugin provider for <b>kotlin.compose</b> with plugin id <b>org.jetbrains.kotlin.plugin.compose</b> and
         * with version reference <b>kotlin</b>
         * <p>
         * This plugin was declared in script '/Users/nickmolargik/Library/Developer/Xcode/DerivedData/Stork-aivqnbzhitpszucvptguuhoaoala/SourcePackages/plugins/stork.output/Stork/skipstone/settings.gradle.kts'
         */
        public Provider<PluginDependency> getCompose() { return createPlugin("kotlin.compose"); }

    }

}
