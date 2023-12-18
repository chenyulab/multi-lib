# Import data from plaintext file.

## Params
input_file = 'T:\multisensory\experiment_355\included\__20230914_10083\supporting_files\parent_fixation.csv'#'~/Desktop/data.csv'
col_sep = ','
csv_opts = {
  :col_sep => col_sep
}
start_row = 2 # Row to start reading data from; first line is row 1 (use 2 to skip reading header if present)

# Denote how columns from the input file will be represented in the datavyu spreadsheet
# This is a nested associative array.
# The outer key is the name of column.
# The inner keys are names of codes, and the values for the inner keys are the indices of input
# columns containing the values for the code. The first column of the input is column 1.
code_map = {
  'parent_ROI' => {
    'onset' => 1,
    'offset' => 2,
    'roi' => 3
  }
}

## Body
require 'Datavyu_API.rb'
require 'csv'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter
begin
  # If input_file is :prompt, open up a file chooser window to let user select input file.
  if(input_file == :prompt)
    txtFilter = FileNameExtensionFilter.new('Text file','txt')
    csvFilter = FileNameExtensionFilter.new('CSV file', 'csv')
    jfc = JFileChooser.new()
    jfc.setAcceptAllFileFilterUsed(false)
    jfc.setFileFilter(csvFilter)
    jfc.addChoosableFileFilter(txtFilter)
    jfc.setMultiSelectionEnabled(false)
    jfc.setDialogTitle('Select transcript text file.')

    ret = jfc.showOpenDialog(javax.swing.JPanel.new())

    if ret != JFileChooser::APPROVE_OPTION
      puts "Invalid selection. Aborting."
      return
    end

    scriptFile = jfc.getSelectedFile()
    fn = scriptFile.getAbsolutePath()
    infile = File.open(fn, 'r')
  else
    # Open input file for read
    infile = File.open(File.expand_path(input_file), 'r')
  end

  # Set up spreadsheet with columns from code_map
  columns = {}
  code_map.each_pair do |column_name, pairs|
    codes = pairs.keys
    columns[column_name] = createVariable(column_name, *(codes - ['ordinal', 'onset', 'offset']))
  end

  # Init struct to keep track of data
  prev_data = {}
  code_map.keys.each{ |x| prev_data[x] = nil }

  # Read lines from the input file and add data
  infile.readlines.each_with_index do |line, idx|
    next unless idx >= (start_row - 1)

    tokens = CSV.parse_line(line, csv_opts)

    # Group data by column
    current_data = {}
    code_map.each_pair do |column_name, pairs|
      values = pairs.values.map{ |i| tokens[i-1] }
      current_data[column_name] = values

      # Make new cell if current data does not match previous data
      unless (values == prev_data[column_name]) || values.all?{ |x| x.nil? }
        ncell = columns[column_name].make_new_cell
        pairs.each_pair do |c, i|
          value = tokens[i-1]
          value = value.to_i if %w(ordinal onset offset).include?(c) # convert to int for ordinal, onset, offset values
          ncell.change_code(c, value)
        end
      end
    end

    prev_data = current_data
  end

  columns.values.each{ |x| set_column(x) }
end
