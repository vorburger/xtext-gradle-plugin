package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.tasks.bundling.Zip
import org.xtext.gradle.idea.tasks.AssembleSandbox

class IdeaPluginPlugin implements Plugin<Project> {
	public static val IDEA_ZIP_TASK_NAME = "ideaZip"

	override apply(Project project) {
		project.plugins.<IdeaComponentPlugin>apply(IdeaComponentPlugin)
		val providedDependencies = project.configurations.getAt(IdeaComponentPlugin.IDEA_PROVIDED_CONFIGURATION_NAME)
		val runtimeDependencies = project.configurations.getAt(JavaPlugin.RUNTIME_CONFIGURATION_NAME)
		val assembleSandbox = project.tasks.getAt(IdeaComponentPlugin.ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox

		val jar = project.tasks.getAt(JavaPlugin.JAR_TASK_NAME)
		assembleSandbox => [
			libraries.from(jar)
			libraries.from(runtimeDependencies.filter [ candidate |
				!providedDependencies.exists[candidate.name == name]
			])
			metaInf.from("META-INF")
		]

		val ideaZip = project.tasks.create(IDEA_ZIP_TASK_NAME, Zip) [
			description = "Creates an installable archive of this plugin"
			group = BasePlugin.BUILD_GROUP
			with(assembleSandbox.plugin)
		]
		project.tasks.getAt(BasePlugin.ASSEMBLE_TASK_NAME).dependsOn(ideaZip)
	}
}