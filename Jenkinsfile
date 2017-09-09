node('GlobalTester') {

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
      sh "cd ${PROJECT_NAME}/${PROJECT_NAME}.releng/ && ${MAVEN_HOME}/bin/mvn ${MAVEN_PARAMS} -Dmaven.test.failure.ignore clean verify"
    }

    stage "Collect test results"
    junit '**/TEST*.xml'
  }

}
