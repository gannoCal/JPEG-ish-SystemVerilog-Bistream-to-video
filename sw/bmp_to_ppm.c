//coded by Jason Thong for COE3DQ5 2020
//convert a *.bmp (bitmap file) to a *.ppm (portable pixel map file)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// print the info for device independent bitmap (DIB) header
void print_DIB_header_info (int dib_header_size) {

	switch (dib_header_size) {
		case 12:
			printf("Header type: BITMAPCOREHEADER\n");
			break;

		case 40:
			printf("Header type: BITMAPINFOHEADER\n");
			break;

		case 52:
			printf("Header type: BITMAPV2INFOHEADER\n");
			break;

		case 56:
			printf("Header type: BITMAPV3INFOHEADER\n");
			break;

		case 64:
			printf("Header type: OS22XBITMAPHEADER\n");
			break;

		case 108:
			printf("Header type: BITMAPV4HEADER\n");
			break;

		case 124:
			printf("Header type: BITMAPV5HEADER\n");
			break;

		default:
			printf("Header type: UNKNOWN\n");
			printf("Exiting\n");
			exit(1);
			break;
	}
}

void Parse_bmp(char *Source_Filename, char *Destination_Filename) {

	unsigned int i, j, index, Image_Rows, Image_Columns;
	unsigned char temp_char, *Image_Data;
	FILE *Source_File, *Destination_File;

	// strcat(Source_Filename, ".bmp");
	// strcat(Destination_Filename, ".ppm");
	printf("Parsing file %s to %s\n", Source_Filename, Destination_Filename);

	// open files
	if ((Source_File = fopen(Source_Filename, "rb")) == NULL) {
		printf("Problem with file %s\n", Source_Filename); exit(1); }
	if ((Destination_File = fopen(Destination_Filename, "wb")) == NULL) {
		printf("Problem with file %s\n", Destination_Filename); exit(1); }

	//read file format (expected BM)
	char file_format[3];
	file_format[0] = fgetc(Source_File);
	file_format[1] = fgetc(Source_File);
	file_format[2] = '\0';
	printf("File format: %s\n", file_format);

	//read file size
	int file_size;
	file_size = fgetc(Source_File);
	for (i=8; i<=24; i+=8)
		file_size += fgetc(Source_File) << i;
	printf("File size: %d\n", file_size);

	// skip four bytes
	for (i=0; i<4; i++)
		fgetc(Source_File);

	//read array_offset
	int array_offset;
	array_offset = fgetc(Source_File);
	for (i=8; i<=24; i+=8)
		array_offset += fgetc(Source_File) << i;
	printf("Array offset: %d\n", array_offset);

	//read DIB header size
	int dib_header_size;
	dib_header_size = fgetc(Source_File);
	for (i=8; i<=24; i+=8)
		dib_header_size += fgetc(Source_File) << i;
	printf("DIB header size: %d\n", dib_header_size);

	if ((dib_header_size + 14) != array_offset) {
		printf("DIB header size: %d\n", dib_header_size);
		printf("Array offset: %d\n", array_offset);
		printf("The difference must be 14 ... exiting\n");
		exit(1);
	}

	print_DIB_header_info(dib_header_size);

	// retrieve image width
	Image_Columns = 0;
	for (i = 0; i < 4; i++) {
		temp_char = fgetc(Source_File);
		Image_Columns += temp_char << (8 * i);
	}
	printf("Image_Columns: %u\n", Image_Columns);

	// retrieve image height
	Image_Rows = 0;
	for (i = 0; i < 4; i++) {
		temp_char = fgetc(Source_File);
		Image_Rows += temp_char << (8 * i);
	}
	printf("Image_Rows: %u\n", Image_Rows);
	if (Image_Rows < 0) {
		printf("Negative image height field - expecting positive value ... exiting!\n");
		exit(1);
	}

	// read color plan
	int colour_plane;
	colour_plane = fgetc(Source_File);
	colour_plane += fgetc(Source_File) << 8;
	if (colour_plane != 1) {
		printf("The plane field is %d - it must be one ... exiting\n", colour_plane);
		exit(1);
	}

	// read bits per colour
	int bit_count;
	bit_count = fgetc(Source_File);
	bit_count += fgetc(Source_File) << 8;
	if (bit_count != 24) {
		printf("Bits per pixel is %d - we expect 24 bits (8 bits per colour) in the BMP file ... exiting\n", bit_count);
		exit(1);
	}

	// read compression mode
	int compression;
	compression = fgetc(Source_File);
	for (i=8; i<=24; i+=8)
		compression += fgetc(Source_File) << i;
	if (compression != 0) {
		printf("Compression mode is %d - we expect this field to be zero (no compression) ... exiting\n", bit_count);
		exit(1);
	}

	// read image size
	int image_size;
	image_size = fgetc(Source_File);
	for (i=8; i<=24; i+=8)
		image_size += fgetc(Source_File) << i;
	printf("Image size: %d\n", image_size);

	int number_of_words_per_row = (Image_Columns * 24 + 31)/ 32;
	int Row_Size = number_of_words_per_row * 4;
	if (Row_Size != 3 * Image_Columns)
		printf("There are %d dummy bytes in each row\n", (Row_Size - 3 * Image_Columns));

	if (image_size == 0) {
		printf("Warning: the image size field has been set to zero by the SW that produced the BMP file\n");
		printf("This is not critical - however the data might be corrupted (check your image visually)\n");
	} else if (image_size != Row_Size * Image_Rows) {
		printf("Image size must be equal to width multiplied by height multiplied by number of bytes per pixel ... exiting\n");
		exit(1);
	}

	if ((Row_Size * Image_Rows) != file_size - dib_header_size - 14) {
		printf("bytes per row x number of rows must be equal to file size - total header size ... exiting\n");
		exit(1);
	}

	// skip the rest of the DIB header (subtract 24 because that's how many bytes have been read from the DIB header
	// (excluding the first 14 bytes) for file size and array offset
	for (i=0; i < dib_header_size-24; i++)
		fgetc(Source_File);

	// memory allocation
	Image_Data = (unsigned char *)malloc(3*Image_Rows*Image_Columns*sizeof(unsigned char));

	// read image
	for (i = 0; i < Image_Rows; i++) {
		for (j = 0; j < Image_Columns; j++) {
			index = (3*(((Image_Rows)-(i)-1)*(Image_Columns)+(j)));
			Image_Data[index+2] = fgetc(Source_File); // B
			Image_Data[index+1] = fgetc(Source_File); // G
			Image_Data[index+0] = fgetc(Source_File); // R
		}
		// skip dummy bytes at the end of each row
		for (j = 0; j < (Row_Size - 3 * Image_Columns); j++)
			fgetc(Source_File);
	}

	// write image
	fprintf(Destination_File, "P6\n%d %d\n255\n", Image_Columns, Image_Rows);
	for (i = 0; i < Image_Rows; i++)
		for (j = 0; j < Image_Columns; j++) {
			index = (3*((i)*(Image_Columns)+(j)));
			fprintf(Destination_File, "%c", Image_Data[index+0]);  // R
			fprintf(Destination_File, "%c", Image_Data[index+1]);  // G
			fprintf(Destination_File, "%c", Image_Data[index+2]);  // B
		}

	fclose(Source_File);
	fclose(Destination_File);

	free(Image_Data);
}


int main(int argc, char **argv) {
	int i, j, k, width, height;
	char input_filename[200], output_filename[200];
	unsigned char *r_image, *g_image, *b_image;
	FILE *file_ptr;
	
	//get input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("Enter the input file name including the .bmp extension: ");
		fscanf(stdin, "%s", input_filename);
	}
	else strcpy(input_filename, argv[1]);
	
	//get output file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("Enter the output file name including the .ppm extension: ");
		fscanf(stdin, "%s", output_filename);
	}
	else strcpy(output_filename, argv[2]);
	
	Parse_bmp(input_filename, output_filename);

	printf("Done :)\n");
	return 0;
}

