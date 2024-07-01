node('GlobalTester') {

  	stage('Clean workspace') {
		dir('jacoco') {
			deleteDir()
		}
	}

	stage('Checkout project') {
		checkout([$class: 'GitSCM', 
			branches: [[name: "${BRANCH_NAME}"]],
			doGenerateSubmoduleConfigurations: false,
			extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${PROJECT_NAME}"],[$class: 'CleanCheckout']],
			submoduleCfg: [],
			userRemoteConfigs: [[credentialsId: '5d73c6ee-e61e-44b3-bce9-881b28a92d60', url: "ssh://git@bitbucket.secunet.de:7999/gt/${PROJECT_NAME}"]]
		])
	}
	  
	stage('Checkout dependencies') {
		repoList = sh returnStdout: true, script: "cat ${PROJECT_NAME}/${PROJECT_NAME}.releng/pom.xml | grep '<module>' | sed -e 's|.*\\.\\.\\/\\.\\.\\/\\([^/]*\\)\\/.*<\\/module>.*|\\1|' | sort -u"
		def repos = repoList.readLines()
		for (String curRepo : repos) {
			echo "Checkout dependencies for '${curRepo}'"				
			checkout([$class: 'GitSCM', 
				branches: [[name: "${BRANCH_NAME}"]],
				doGenerateSubmoduleConfigurations: false,
				extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${curRepo}"],[$class: 'CleanCheckout']],
				submoduleCfg: [],
				userRemoteConfigs: [[credentialsId: '5d73c6ee-e61e-44b3-bce9-881b28a92d60', url: "ssh://git@bitbucket.secunet.de:7999/gt/${curRepo}"]]
			])
		}
	}

	stage('Build') {
		wrap([$class: 'Xvnc', takeScreenshot: false, useXauthority: true]) {
			// Precondition: Install JDK as tool (https://hudson.e.secunet.de/hudson/configureTools/) with following JDK_HOME_ID as 'Name'; e.g. 'OpenJDK 17.0.8'
			def JAVA_HOME = tool "${JDK_HOME_ID}"
 			echo "JAVA_HOME: ${JAVA_HOME}"
 			// Precondition: Install mvn as tool automatically (https://hudson.e.secunet.de/hudson/configureTools/) with following MAVEN_ID as 'Name'; e.g. 'maven-3.9.6'
			// Local install dir will be /mnt/buildfs/tools/hudson.tasks.Maven_MavenInstallation/${MAVEN_ID}
			def mvnHome = tool "${MAVEN_ID}"
			echo "mvnHome: ${mvnHome}"
			sh "export PATH=${JAVA_HOME}/bin:$PATH && cd ${PROJECT_NAME}/${PROJECT_NAME}.releng/ && ${mvnHome}/bin/mvn ${MAVEN_PARAMS} -DforceContextQualifier=`${MAVEN_CONTEXT_QUALIFIER}` -Dmaven.test.failure.ignore -DfailIfNoTests=false ${MAVEN_TARGETS}"
		}
	}

	stage ('Collect artifacts') {
		def collectArtifacts = "${COLLECT_ARTIFACTS}"
		echo "collectArtifacts: ${collectArtifacts}"
		def productOnly = "product_only"
		if ("${productOnly}".equals("${collectArtifacts}")) {
			echo "Collect 'product only' artifacts"
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*product-*.zip'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*product-*.tar.gz'
		} else {
			echo "Collect all artifacts"
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/resource/*.list'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/html/*.html'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*site*.zip'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*product-*.zip'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*deploy*.zip'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*uiTests.zip'
			archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*product-*.tar.gz'
			// archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*site*.tar.gz'
			// archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*deploy*.tar.gz'
			// archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*uiTests.tar.gz'
			junit '**/TEST*.xml'
		}
	}
}