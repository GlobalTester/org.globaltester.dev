node('GlobalTester') {

  stage('Clean workspace') {
    dir('jacoco'){
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
      echo curRepo

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
      sh "cd ${PROJECT_NAME}/${PROJECT_NAME}.releng/ && ${MAVEN_HOME}/bin/mvn ${MAVEN_PARAMS} -DforceContextQualifier=`date --date=tomorrow +%Y%m%d` -Dmaven.test.failure.ignore ${MAVEN_TARGETS}"
    }
  }

  stage ('Collect artifacts') {
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/resource/*.list'
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/html/*.html'
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*site*.zip'
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*product-*.zip'
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/products/*deploy*.zip'
    archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*uiTests.zip'
    junit '**/TEST*.xml'
  }

}
