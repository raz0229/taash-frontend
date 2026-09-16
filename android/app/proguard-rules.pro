# WorkManager
-keep class androidx.work.** { *; }

# R8 full-mode strips the Room-generated WorkDatabase implementation because
# Room instantiates it by reflection. Without it the androidx.startup
# InitializationProvider fails during attach -> instant crash on launch
# (java.lang.RuntimeException: Failed to create an instance of
# androidx.work.impl.WorkDatabase).
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.model.** { *; }

# Flutter uses the app's WorkManager for plugin-internal ScheduledWorker jobs.
-keep class **.ScheduledWorker { *; }

# AndroidX Startup
-keep class androidx.startup.** { *; }