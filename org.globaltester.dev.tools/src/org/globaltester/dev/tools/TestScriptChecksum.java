package org.globaltester.dev.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.SequenceInputStream;
import java.util.Vector;
import java.util.zip.Adler32;
import java.util.zip.CheckedInputStream;

/**
 * Helper to build checksums in GlobalTester Testscript projects.
 * 
 * @author amay
 *
 */
public class TestScriptChecksum {
	
	private long checksum;

	private String project;
	private String fileName;
	private String destFile;

	/**
	 * Calculate and store the checksum for a given testscript project.
	 * <p/>
	 * Commandline args as follows:<br/>
	 * project [filelist [outputfile]] 
	 * @param args
	 */
	public static void main(String[] args) {
		TestScriptChecksum checksumGenerator = new TestScriptChecksum();
		
		// set project
		if (args.length >= 1) {
			checksumGenerator.project = args[0];
		} else {
			System.err.println("Please provide a project path in first argument");
			System.exit(1);
		}

		// set filelist
		if (args.length >= 2) {
			checksumGenerator.fileName = args[1];
		} else {
			checksumGenerator.fileName = checksumGenerator.project + File.separator + "filelist.a32";
		}

		// set outputfile
		if (args.length >= 3) {
			checksumGenerator.destFile = args[3];
		} else {
			checksumGenerator.destFile = checksumGenerator.project + File.separator + "checksum.a32";
		}
		
		System.out.println("args.length " + args.length);
		System.out.println("checksumGenerator.project " + checksumGenerator.project);
		System.out.println("checksumGenerator.fileName " + checksumGenerator.fileName);
		System.out.println("checksumGenerator.destFile " + checksumGenerator.destFile);
		
		//do the work
		checksumGenerator.calculateChecksum();
		checksumGenerator.writeChecksumFile();
	}

	private void writeChecksumFile() {
		System.out.println("Write checksum file");
		
		File checksumFile = new File(destFile);

		try {
			OutputStream os = new FileOutputStream(checksumFile);
			OutputStreamWriter osw = new OutputStreamWriter(os);
			osw.write(String.valueOf(checksum));
			osw.flush();
			osw.close();
			os.close();

		} catch (FileNotFoundException e) {
			System.err.println("Can't write outputfile: File not found " + destFile);
			System.out.println(e);
			e.printStackTrace();
			System.exit(1);
		} catch (IOException e) {
			System.err.println("Can't write outputfile: IOException " + destFile);
			System.out.println(e);
			e.printStackTrace();
			System.exit(1);
		}

	}

	private void calculateChecksum() {
		System.out.println("Calculating testscript checksum");
		
		Vector<FileInputStream> v = new Vector<FileInputStream>();
		BufferedReader br;
		try {
			br = new BufferedReader(new FileReader(fileName));
			String currentLine;
			while ((currentLine = br.readLine()) != null) {
				String currentFile = project + File.separator + currentLine;
				v.addElement(new FileInputStream(currentFile));
				System.out.println("Added file: " + currentFile);
			}
			System.out.println("Added " + v.size() + " files from " + fileName);
			br.close();
		} catch (FileNotFoundException e) {
			System.err.println("Can't read filelist: File not found " + destFile);
			System.out.println(e);
			e.printStackTrace();
			System.exit(1);
		} catch (IOException e) {
			System.err.println("Can't read filelist: IOException " + destFile);
			System.out.println(e);
			e.printStackTrace();
			System.exit(1);
		}

		// read files and build checksum:
		try {
			InputStream seq = new SequenceInputStream(v.elements());

			CheckedInputStream in = new CheckedInputStream(seq, new Adler32());

			byte[] buf = new byte[4096];

			while ((in.read(buf)) > 0) {
				// do nothing :)
			}
			checksum = in.getChecksum().getValue();
			in.close();
		} catch (IOException e) {
			System.err.println("Error processing filelist");
			System.out.println(e);
			e.printStackTrace();
			System.exit(1);
			}

		System.out.println("Checksum: " + checksum);

	}

}
