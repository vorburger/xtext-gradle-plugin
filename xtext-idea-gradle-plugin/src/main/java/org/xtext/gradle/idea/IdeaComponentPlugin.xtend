package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.Classpath
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.gradle.plugins.ide.eclipse.model.Library
import org.gradle.plugins.ide.eclipse.model.internal.FileReferenceFactory
import org.xtext.gradle.idea.tasks.DownloadIdea
import org.xtext.gradle.idea.tasks.IdeaExtension

class IdeaComponentPlugin implements Plugin<Project> {

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		project.plugins.<JavaPlugin>apply(JavaPlugin)
		val idea = project.extensions.getByType(IdeaExtension)
		
		val compile = project.configurations.getAt("compile")
		compile.exclude(#{"module" -> "guava"})
		compile.exclude(#{"module" -> "log4j"})

		val ideaProvided = project.configurations.create("ideaProvided")
		
		project.afterEvaluate [
			val downloadTask = project.tasks.getByName("downloadIdea") as DownloadIdea

			project.dependencies.add(ideaProvided.name, idea.ideaLibs)
			project.convention.getPlugin(JavaPluginConvention).sourceSets.forEach [
				compileClasspath = compileClasspath.plus(ideaProvided)
			]
			
			project.plugins.withType(EclipsePlugin) [
				project.tasks.getByName("eclipseClasspath").dependsOn(downloadTask)
				project.extensions.getByType(EclipseModel).classpath => [
					plusConfigurations.add(ideaProvided)

					val fileReferenceFactory = new FileReferenceFactory
					val ideaLibs = idea.ideaLibs
					val sourceZip = idea.sourcesZip
					file.whenMerged.add [ Classpath it |
						entries.filter(Library).filter[ideaLibs.contains(library.file)].forEach [
							sourcePath = fileReferenceFactory.fromFile(sourceZip)
						]
					]
				]
			]
		]
	}

}