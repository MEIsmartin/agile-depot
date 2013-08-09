require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  test "buying a product" do
    # clear the cart before starting
    LineItem.delete_all
    Order.delete_all
    # load the ruby product as a variable
    ruby_book = products(:ruby)

    # User goes to the store
    get "/"
    assert_response :success
    assert_template "index"

    # Select a product, add to cart
    xml_http_request :post, '/line_items', product_id: ruby_book.id
    assert_response :success

    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product

    # Check out
    get "/orders/new"
    assert_response :success
    assert_template "new"

    # save the order and check that the cart is now empty
    post_via_redirect "/orders",
      order: {
        name: 'Dave Thomas',
        address: '123 The Street',
        email: 'dave@example.com',
        pay_type: 'Check'
      }
    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size

    # check the database to make sure the order has been saved
    orders = Order.all
    assert_equal 1, orders.size
    order = orders[0]

    assert_equal "Dave Thomas", order.name

    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product

    # Verify the mail was correctly address
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'depot@example.com', mail[:from].value
    assert_equal 'Pragmatic Store Order Confirmation', mail.subject
  end
end
