require 'csv'
require 'octokit'

CSV_CONFIG = { headers: true, header_converters: :symbol, return_headers: true }


def create_review_comments
  headers = []
  reviews = {}
  CSV.foreach('takeaway_challenge_oct15.csv', CSV_CONFIG) do |row|
    if row.header_row?
      headers = row
      headers.delete :what_is_the_reviewees_github_username
      headers.delete :your_name
      headers.delete :did_you_find_this_form_useful_in_completing_the_review
      headers.delete :any_additional_comments_on_the_code_you_reviewed
      headers.delete :whose_challenge_are_you_reviewing
      headers.delete :timestamp
      next
    end
    comments = "You had airport challenge reviewed by **#{row[:your_name]}**.\n"
    comments << "### The good points are:\n"
    headers.each do |header|
      comments << "* #{row.field(header[0])}\n" if row.field(header[0])
    end

    comments << "\n### You should consider the following improvements:"
    headers.each do |header|
      comments << "* #{header[1]}\n" unless row.field(header[0])
    end

    if row.field(:any_additional_comments_on_the_code_you_reviewed)
      comments << "\n### Additional comments:\n"
      comments << row.field(:any_additional_comments_on_the_code_you_reviewed) + "\n"
    end
    comments << "\nsee https://github.com/makersacademy/takeaway_challenge/blob/master/docs/review.md for more details"

    reviews[row[:what_is_the_reviewees_github_username]] = comments
  end
  reviews
end

def update_pull_requests
  client =  Octokit::Client.new access_token: ENV['MAKERS_TOOLBELT_GITHUB_TOKEN']
  pull_requests = client.pull_requests 'makersacademy/takeaway-challenge', state: 'open', per_page: 100

  pull_requests.each do |pr|
    puts create_review_comments[pr.user.login]
    #client.add_comment 'makersacademy/takeaway-challenge', 170, create_review_comments.values.last
    return
  end
end
#create_review_comments
update_pull_requests
