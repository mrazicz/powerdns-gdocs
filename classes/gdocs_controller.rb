class GdocsController
  require "google_spreadsheet"
  
  # create Object
  # param account ... hash with account info(user, pass, spreadsheet key)
  def initialize(user, pass, key)
    @user = user
    @pass = pass
    @key  = key
  end

  # connect to gmail account
  def connect
    begin
      @session = GoogleSpreadsheet.login(@user, @pass)
    rescue GoogleSpreadsheet::AuthenticationError
      abort("Authentication for #{@user} failed!")
    end  
  end

  # get array of records in worksheet
  def get_records
    begin
      # select spreadsheet by key
      ws = @session.spreadsheet_by_key(@key).worksheets[0]
      records = Hash.new

      for row in 3..ws.num_rows
        row_record = []
        for col in 1..3
          row_record[col - 1] = ws[row, col]
        end
        records[row] = row_record
      end
      records

    rescue GoogleSpreadsheet::Error
      abort("spreadsheet.google.com returned error!")
    end
  end

  # set status in worksheet at given row; default status is "active"
  def set_status(row, status = "active")
    ws[row, 3] = status
  end
end
