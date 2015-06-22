In order to setup a fresh build area create an empty directory and cd into it.
From there clone com.hjp.releng:
git clone  ssh://git@tourmaline.intranet.hjp-consulting.com/com.hjp.releng
Now execute the checkout script (this script is shell/OS independent as long as you have git on your PATH)
./com.hjp.releng/com.hjp.releng/checkout.bat
Depending on your connectivity to the providing servers this might take some time.
Gratulations, your have a complete workingcopy.

In order to build specific projects change in the appropriate directory and build them with
mvn clean verify
This should work for all *.releng projects that build the specific products. The project com.hjp.releng buildas all products in one build.

If you followed the instructions above you can easily import all projects in your Eclipse workspace. Just select "Import... > General > Existing Projects into Workspace". Follow the wizzard, you can select the root directory you cloned repositories to, this will detect all relevant projects. Make sure not to copy them, this will allow eGit to operate on your exisitng repository clone.



