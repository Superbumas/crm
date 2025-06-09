<?php
/**
 * Plugin Name: VakaSport CRM Connector
 * Plugin URI: https://vakasport.com
 * Description: Connects your WordPress/WooCommerce store with VakaSport CRM
 * Version: 1.0.0
 * Author: VakaSport
 * Author URI: https://vakasport.com
 * Text Domain: vakasport-crm
 * WC requires at least: 5.0
 * WC tested up to: 8.3
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

// Define plugin constants
define('VAKASPORT_CRM_VERSION', '1.0.0');
define('VAKASPORT_CRM_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('VAKASPORT_CRM_PLUGIN_URL', plugin_dir_url(__FILE__));

/**
 * Main plugin class
 */
class VakaSport_CRM_Connector {

    /**
     * Plugin instance
     */
    private static $instance = null;

    /**
     * CRM API URL
     */
    private $api_url;

    /**
     * API Authentication token
     */
    private $api_token;

    /**
     * Get plugin instance
     */
    public static function instance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Constructor
     */
    public function __construct() {
        // Check if WooCommerce is active
        if (!$this->check_woocommerce_active()) {
            add_action('admin_notices', array($this, 'woocommerce_missing_notice'));
            return;
        }

        // Load settings
        $this->api_url = get_option('vakasport_crm_api_url', '');
        $this->api_token = get_option('vakasport_crm_api_token', '');

        // Initialize the plugin
        $this->init();
    }

    /**
     * Initialize the plugin
     */
    public function init() {
        // Load textdomain for translations
        add_action('plugins_loaded', array($this, 'load_textdomain'));

        // Admin settings
        add_action('admin_menu', array($this, 'add_admin_menu'));
        add_action('admin_init', array($this, 'register_settings'));

        // Product hooks
        add_action('woocommerce_update_product', array($this, 'product_updated'), 10, 2);
        add_action('woocommerce_new_product', array($this, 'product_created'), 10, 2);
        add_action('woocommerce_delete_product', array($this, 'product_deleted'), 10);

        // Order hooks
        add_action('woocommerce_order_status_changed', array($this, 'order_status_changed'), 10, 4);
        add_action('woocommerce_new_order', array($this, 'order_created'), 10, 1);

        // Custom REST API endpoints
        add_action('rest_api_init', array($this, 'register_rest_routes'));
    }

    /**
     * Load plugin textdomain
     */
    public function load_textdomain() {
        load_plugin_textdomain('vakasport-crm', false, basename(dirname(__FILE__)) . '/languages');
    }

    /**
     * Check if WooCommerce is active
     */
    public function check_woocommerce_active() {
        return in_array('woocommerce/woocommerce.php', apply_filters('active_plugins', get_option('active_plugins')));
    }

    /**
     * WooCommerce missing notice
     */
    public function woocommerce_missing_notice() {
        ?>
        <div class="notice notice-error">
            <p><?php _e('VakaSport CRM Connector requires WooCommerce to be installed and active.', 'vakasport-crm'); ?></p>
        </div>
        <?php
    }

    /**
     * Add admin menu
     */
    public function add_admin_menu() {
        add_submenu_page(
            'woocommerce',
            __('VakaSport CRM', 'vakasport-crm'),
            __('VakaSport CRM', 'vakasport-crm'),
            'manage_woocommerce',
            'vakasport-crm',
            array($this, 'admin_page')
        );
    }

    /**
     * Register settings
     */
    public function register_settings() {
        register_setting('vakasport_crm_settings', 'vakasport_crm_api_url');
        register_setting('vakasport_crm_settings', 'vakasport_crm_api_token');
        register_setting('vakasport_crm_settings', 'vakasport_crm_sync_products');
        register_setting('vakasport_crm_settings', 'vakasport_crm_sync_orders');
    }

    /**
     * Admin page
     */
    public function admin_page() {
        ?>
        <div class="wrap">
            <h1><?php _e('VakaSport CRM Integration', 'vakasport-crm'); ?></h1>
            
            <form method="post" action="options.php">
                <?php settings_fields('vakasport_crm_settings'); ?>
                <?php do_settings_sections('vakasport_crm_settings'); ?>
                
                <table class="form-table">
                    <tr valign="top">
                        <th scope="row"><?php _e('CRM API URL', 'vakasport-crm'); ?></th>
                        <td>
                            <input type="url" name="vakasport_crm_api_url" class="regular-text" 
                                value="<?php echo esc_attr(get_option('vakasport_crm_api_url')); ?>" />
                            <p class="description"><?php _e('Enter the URL of your VakaSport CRM API', 'vakasport-crm'); ?></p>
                        </td>
                    </tr>
                    
                    <tr valign="top">
                        <th scope="row"><?php _e('API Token', 'vakasport-crm'); ?></th>
                        <td>
                            <input type="password" name="vakasport_crm_api_token" class="regular-text" 
                                value="<?php echo esc_attr(get_option('vakasport_crm_api_token')); ?>" />
                            <p class="description"><?php _e('Enter your CRM API token', 'vakasport-crm'); ?></p>
                        </td>
                    </tr>
                    
                    <tr valign="top">
                        <th scope="row"><?php _e('Sync Settings', 'vakasport-crm'); ?></th>
                        <td>
                            <label>
                                <input type="checkbox" name="vakasport_crm_sync_products" value="1" 
                                    <?php checked(1, get_option('vakasport_crm_sync_products', 1)); ?> />
                                <?php _e('Sync products with CRM', 'vakasport-crm'); ?>
                            </label>
                            <br>
                            <label>
                                <input type="checkbox" name="vakasport_crm_sync_orders" value="1" 
                                    <?php checked(1, get_option('vakasport_crm_sync_orders', 1)); ?> />
                                <?php _e('Sync orders with CRM', 'vakasport-crm'); ?>
                            </label>
                        </td>
                    </tr>
                </table>
                
                <?php submit_button(); ?>
            </form>
            
            <hr>
            
            <h2><?php _e('Manual Sync', 'vakasport-crm'); ?></h2>
            <p><?php _e('Use these buttons to manually sync data with the CRM:', 'vakasport-crm'); ?></p>
            
            <div class="crm-sync-buttons">
                <button id="sync-all-products" class="button button-primary">
                    <?php _e('Sync All Products', 'vakasport-crm'); ?>
                </button>
                
                <button id="sync-all-orders" class="button button-primary">
                    <?php _e('Sync All Orders', 'vakasport-crm'); ?>
                </button>
            </div>
            
            <div id="sync-status" class="notice notice-info" style="display: none;">
                <p></p>
            </div>
            
            <script>
                jQuery(document).ready(function($) {
                    // Sync all products
                    $('#sync-all-products').on('click', function(e) {
                        e.preventDefault();
                        
                        $('#sync-status').show().removeClass('notice-error notice-success').addClass('notice-info');
                        $('#sync-status p').text('<?php _e('Syncing products...', 'vakasport-crm'); ?>');
                        
                        $.ajax({
                            url: '<?php echo rest_url('vakasport-crm/v1/sync-products'); ?>',
                            method: 'POST',
                            beforeSend: function(xhr) {
                                xhr.setRequestHeader('X-WP-Nonce', '<?php echo wp_create_nonce('wp_rest'); ?>');
                            },
                            success: function(response) {
                                $('#sync-status').removeClass('notice-info notice-error').addClass('notice-success');
                                $('#sync-status p').text(response.message);
                            },
                            error: function(xhr) {
                                $('#sync-status').removeClass('notice-info notice-success').addClass('notice-error');
                                $('#sync-status p').text('Error: ' + xhr.responseJSON.message);
                            }
                        });
                    });
                    
                    // Sync all orders
                    $('#sync-all-orders').on('click', function(e) {
                        e.preventDefault();
                        
                        $('#sync-status').show().removeClass('notice-error notice-success').addClass('notice-info');
                        $('#sync-status p').text('<?php _e('Syncing orders...', 'vakasport-crm'); ?>');
                        
                        $.ajax({
                            url: '<?php echo rest_url('vakasport-crm/v1/sync-orders'); ?>',
                            method: 'POST',
                            beforeSend: function(xhr) {
                                xhr.setRequestHeader('X-WP-Nonce', '<?php echo wp_create_nonce('wp_rest'); ?>');
                            },
                            success: function(response) {
                                $('#sync-status').removeClass('notice-info notice-error').addClass('notice-success');
                                $('#sync-status p').text(response.message);
                            },
                            error: function(xhr) {
                                $('#sync-status').removeClass('notice-info notice-success').addClass('notice-error');
                                $('#sync-status p').text('Error: ' + xhr.responseJSON.message);
                            }
                        });
                    });
                });
            </script>
        </div>
        <?php
    }

    /**
     * Product updated
     */
    public function product_updated($product_id, $product) {
        if (!get_option('vakasport_crm_sync_products', 1)) {
            return;
        }
        
        $this->sync_product($product_id);
    }

    /**
     * Product created
     */
    public function product_created($product_id, $product) {
        if (!get_option('vakasport_crm_sync_products', 1)) {
            return;
        }
        
        $this->sync_product($product_id);
    }

    /**
     * Product deleted
     */
    public function product_deleted($product_id) {
        if (!get_option('vakasport_crm_sync_products', 1)) {
            return;
        }
        
        // Call API to delete product
        $this->api_request('DELETE', "/api/v1/wordpress/product/{$product_id}");
    }

    /**
     * Order status changed
     */
    public function order_status_changed($order_id, $from_status, $to_status, $order) {
        if (!get_option('vakasport_crm_sync_orders', 1)) {
            return;
        }
        
        $this->sync_order($order_id);
    }

    /**
     * Order created
     */
    public function order_created($order_id) {
        if (!get_option('vakasport_crm_sync_orders', 1)) {
            return;
        }
        
        $this->sync_order($order_id);
    }

    /**
     * Sync product to CRM
     */
    public function sync_product($product_id) {
        $product = wc_get_product($product_id);
        
        if (!$product) {
            return;
        }
        
        // Build product data
        $product_data = array(
            'id' => $product->get_id(),
            'sku' => $product->get_sku(),
            'name' => $product->get_name(),
            'description_html' => $product->get_description(),
            'price_final' => $product->get_price(),
            'price_old' => $product->get_regular_price(),
            'quantity' => $product->get_stock_quantity(),
            'category' => $this->get_product_categories($product),
            'barcode' => $product->get_meta('_barcode'),
            'manufacturer' => $product->get_meta('_manufacturer'),
            'model' => $product->get_meta('_model'),
            'weight_kg' => $product->get_weight(),
            'main_image_url' => wp_get_attachment_url($product->get_image_id()),
            'extra_image_urls' => $this->get_product_gallery_urls($product)
        );
        
        // Send to CRM
        $response = $this->api_request('POST', "/api/v1/wordpress/product", $product_data);
    }

    /**
     * Sync order to CRM
     */
    public function sync_order($order_id) {
        $order = wc_get_order($order_id);
        
        if (!$order) {
            return;
        }
        
        // Build order data
        $order_data = array(
            'id' => $order->get_id(),
            'number' => $order->get_order_number(),
            'status' => $order->get_status(),
            'date_created' => $order->get_date_created()->format('Y-m-d H:i:s'),
            'total' => $order->get_total(),
            'shipping_total' => $order->get_shipping_total(),
            'tax_total' => $order->get_total_tax(),
            'customer_note' => $order->get_customer_note(),
            'payment_method' => $order->get_payment_method_title(),
            'billing' => array(
                'first_name' => $order->get_billing_first_name(),
                'last_name' => $order->get_billing_last_name(),
                'company' => $order->get_billing_company(),
                'address_1' => $order->get_billing_address_1(),
                'address_2' => $order->get_billing_address_2(),
                'city' => $order->get_billing_city(),
                'postcode' => $order->get_billing_postcode(),
                'country' => $order->get_billing_country(),
                'email' => $order->get_billing_email(),
                'phone' => $order->get_billing_phone()
            ),
            'shipping' => array(
                'first_name' => $order->get_shipping_first_name(),
                'last_name' => $order->get_shipping_last_name(),
                'company' => $order->get_shipping_company(),
                'address_1' => $order->get_shipping_address_1(),
                'address_2' => $order->get_shipping_address_2(),
                'city' => $order->get_shipping_city(),
                'postcode' => $order->get_shipping_postcode(),
                'country' => $order->get_shipping_country()
            ),
            'line_items' => array()
        );
        
        // Add line items
        foreach ($order->get_items() as $item_id => $item) {
            $product = $item->get_product();
            $order_data['line_items'][] = array(
                'id' => $item_id,
                'name' => $item->get_name(),
                'sku' => $product ? $product->get_sku() : '',
                'quantity' => $item->get_quantity(),
                'price' => $item->get_total() / $item->get_quantity(),
                'total' => $item->get_total()
            );
        }
        
        // Send to CRM
        $response = $this->api_request('POST', "/api/v1/wordpress/order", $order_data);
    }

    /**
     * Register REST API routes
     */
    public function register_rest_routes() {
        register_rest_route('vakasport-crm/v1', '/sync-products', array(
            'methods' => 'POST',
            'callback' => array($this, 'rest_sync_products'),
            'permission_callback' => array($this, 'rest_api_permissions')
        ));
        
        register_rest_route('vakasport-crm/v1', '/sync-orders', array(
            'methods' => 'POST',
            'callback' => array($this, 'rest_sync_orders'),
            'permission_callback' => array($this, 'rest_api_permissions')
        ));
        
        register_rest_route('vakasport-crm/v1', '/product/(?P<id>\d+)', array(
            'methods' => 'PUT',
            'callback' => array($this, 'rest_update_product'),
            'permission_callback' => array($this, 'rest_api_permissions')
        ));
    }

    /**
     * REST API permissions check
     */
    public function rest_api_permissions() {
        // For requests from WordPress admin
        if (current_user_can('manage_woocommerce')) {
            return true;
        }
        
        // For requests from CRM
        $auth_header = isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '';
        
        if (strpos($auth_header, 'Bearer ') === 0) {
            $token = substr($auth_header, 7);
            return $token === get_option('vakasport_crm_api_token');
        }
        
        return false;
    }

    /**
     * REST API - Sync all products
     */
    public function rest_sync_products($request) {
        $products = wc_get_products(array(
            'limit' => -1,
            'status' => 'publish'
        ));
        
        $count = 0;
        foreach ($products as $product) {
            $this->sync_product($product->get_id());
            $count++;
        }
        
        return array(
            'success' => true,
            'message' => sprintf(__('%d products synced successfully', 'vakasport-crm'), $count)
        );
    }

    /**
     * REST API - Sync all orders
     */
    public function rest_sync_orders($request) {
        $orders = wc_get_orders(array(
            'limit' => 100,
            'orderby' => 'date',
            'order' => 'DESC'
        ));
        
        $count = 0;
        foreach ($orders as $order) {
            $this->sync_order($order->get_id());
            $count++;
        }
        
        return array(
            'success' => true,
            'message' => sprintf(__('%d orders synced successfully', 'vakasport-crm'), $count)
        );
    }

    /**
     * REST API - Update product
     */
    public function rest_update_product($request) {
        $product_id = $request->get_param('id');
        $product_data = $request->get_params();
        
        $product = wc_get_product($product_id);
        
        if (!$product) {
            return new WP_Error(
                'product_not_found',
                __('Product not found', 'vakasport-crm'),
                array('status' => 404)
            );
        }
        
        // Update product data
        if (isset($product_data['name'])) {
            $product->set_name($product_data['name']);
        }
        
        if (isset($product_data['sku'])) {
            $product->set_sku($product_data['sku']);
        }
        
        if (isset($product_data['description_html'])) {
            $product->set_description($product_data['description_html']);
        }
        
        if (isset($product_data['price_final'])) {
            $product->set_price($product_data['price_final']);
            $product->set_sale_price($product_data['price_final']);
        }
        
        if (isset($product_data['price_old'])) {
            $product->set_regular_price($product_data['price_old']);
        }
        
        if (isset($product_data['quantity'])) {
            $product->set_stock_quantity($product_data['quantity']);
            $product->set_manage_stock(true);
            $product->set_stock_status($product_data['quantity'] > 0 ? 'instock' : 'outofstock');
        }
        
        // Save product
        $product->save();
        
        return array(
            'success' => true,
            'message' => __('Product updated successfully', 'vakasport-crm'),
            'product_id' => $product->get_id()
        );
    }

    /**
     * Get product categories as string
     */
    private function get_product_categories($product) {
        $terms = get_the_terms($product->get_id(), 'product_cat');
        
        if (empty($terms) || is_wp_error($terms)) {
            return '';
        }
        
        $categories = array();
        foreach ($terms as $term) {
            $categories[] = $term->name;
        }
        
        return implode(', ', $categories);
    }

    /**
     * Get product gallery image URLs
     */
    private function get_product_gallery_urls($product) {
        $attachment_ids = $product->get_gallery_image_ids();
        $urls = array();
        
        foreach ($attachment_ids as $attachment_id) {
            $urls[] = wp_get_attachment_url($attachment_id);
        }
        
        return $urls;
    }

    /**
     * Make API request to CRM
     */
    private function api_request($method, $endpoint, $data = null) {
        if (empty($this->api_url) || empty($this->api_token)) {
            return array('success' => false, 'message' => 'API configuration missing');
        }
        
        $url = rtrim($this->api_url, '/') . $endpoint;
        
        $args = array(
            'method' => $method,
            'headers' => array(
                'Authorization' => 'Bearer ' . $this->api_token,
                'Content-Type' => 'application/json'
            ),
            'timeout' => 30
        );
        
        if ($data !== null) {
            $args['body'] = json_encode($data);
        }
        
        $response = wp_remote_request($url, $args);
        
        if (is_wp_error($response)) {
            return array(
                'success' => false,
                'message' => $response->get_error_message()
            );
        }
        
        $body = json_decode(wp_remote_retrieve_body($response), true);
        $status_code = wp_remote_retrieve_response_code($response);
        
        if ($status_code >= 200 && $status_code < 300) {
            return array(
                'success' => true,
                'data' => $body
            );
        } else {
            return array(
                'success' => false,
                'message' => isset($body['message']) ? $body['message'] : 'Unknown error',
                'status_code' => $status_code
            );
        }
    }
}

// Initialize the plugin
function vakasport_crm_init() {
    return VakaSport_CRM_Connector::instance();
}

// Start the plugin
vakasport_crm_init(); 